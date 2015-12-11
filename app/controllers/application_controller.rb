class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_locale
  before_filter :check_for_initial_install
  before_filter :set_version
  before_filter :compute_pending_moderation
  before_filter :apply_relative_root
  around_filter :set_time_zone
  helper_method :webserver_supports_restart?
  helper_method :current_screen
  define_callbacks :auth_plugin
  ConcertoPlugin.install_callbacks(self) 

  # Note on error handling: in general exceptions are caught by Rails
  # Middleware and routed to Concerto's ErrorsController. Authorization
  # errors, however, are handled by this file (further below).

  # Current Ability for CanCan authorization
  # This matches CanCan's code but is here to be explicit,
  # since we modify @current_ability below for plugins.
  def current_ability
    @current_ability ||= ::Ability.new(current_accessor)
  end

  # Determine the current logged-in screen or user to be used for auth
  # on the current action.
  # Used by current_ability and use_plugin_ability
  def current_accessor
    if @screen_api
      @current_accessor ||= current_screen
    end
    @current_accessor ||= current_user
  end

  # current_screen finds the currently authenticated screen based on
  # a cookie or HTTP basic auth sent with the request. Remember,
  # this is only used on actions with the screen_api filter. On all
  # other actions, screen auth is ignored and the current_accessor
  # is the logged in user or anonymous.
  def current_screen
    if @current_screen.nil?
      unless request.authorization.blank?
        (user,pass) = http_basic_user_name_and_password
        if user=="screen" and !pass.nil?
          @current_screen = Screen.find_by_screen_token(pass)
          if params.has_key? :request_cookie
            cookies.permanent[:concerto_screen_token] = pass
          end
        end
      end
      if @current_screen.nil? and cookies.has_key? :concerto_screen_token
        token = cookies[:concerto_screen_token]
        @current_screen = Screen.find_by_screen_token(token)
      end
    end
    @current_screen
  end

  # This method allows the Frontend to circumvent normal screen auth
  # in order to support legacy unsecured screens. Should not be used
  # outside the Frontend controllers.
  def allow_screen_if_unsecured (screen)
    if screen.unsecured? || screen.auth_by_mac?
      @current_screen = screen
      @current_ability = nil
    end
  end

  def http_basic_user_name_and_password
    ActionController::HttpAuthentication::Basic.user_name_and_password(request)
  end

  def sign_in_screen(screen)
    token = screen.generate_screen_token!
    cookies.permanent[:concerto_screen_token]=token
  end

  def sign_out_screen
    if !current_screen.nil?
      current_screen.clear_screen_token!
      @current_screen = nil
    end
    cookies.permanent[:concerto_screen_token]=""
  end

  # Call this with a before filter to indicate that the current action
  # should be treated as a Screen API page. On Screen API pages, the
  # current logged-in screen (if there is one) is used instead of the
  # current user. Screen API pages may only be viewed by authenticated
  # screens.
  def screen_api
    @screen_api=true
  end

  def restart_webserver
    unless webserver_supports_restart?
      flash[:notice] = t(:wont_write_restart_txt)
      return false
    end
    begin
      File.open("tmp/restart.txt", "w") {}
      return true
    rescue
      #generally a write permission error
      flash[:notice] = t(:cant_write_restart_txt)
      return false
    end
  end

  def set_time_zone(&block)
    if user_signed_in? && !current_user.time_zone.nil?
      Time.use_zone(current_user.time_zone, &block)
    else
      Time.use_zone(ConcertoConfig[:system_time_zone], &block)
    end
  end

  def webserver_supports_restart?
    #add any webservers that don't support tmp/restart.txt to this array
    no_restart_txt = ["webrick"]
    no_restart_txt.each do |w|
      #check if the server environment contains a webserver that doesn't support restart.txt
      #This is NOT foolproof - a webserver may elect not to send this
      server_match = /\S*#{w}/.match(env['SERVER_SOFTWARE'].to_s.downcase)
      if server_match.nil?
        return true
      else
        return false
      end
    end
  end

  def rake_precompile
    require 'rake'
    Rake.load_rakefile Rails.root.join( 'Rakefile' )
    Rake::Task['assets:precompile'].invoke
  end

  def precompile_error_catch
    require 'yaml'
    concerto_base_config = YAML.load_file("./config/concerto.yml")
    if concerto_base_config['compile_production_assets'] == true
      if File.exist?('public/assets/manifest.yml') == false && Rails.env.production?
        rake_precompile()
        restart_webserver()
      end
    end
  end

  # Allow views in the main application to do authorization
  # checks for plugins.
  def use_plugin_ability(mod, &block)
    switch_to_plugin_ability(mod)
    yield
    switch_to_main_app_ability
  end

  # Store the current ability (if defined) and switch to the ability
  # class for the specified plugin, if it has one.
  # Always call switch_to_main_app_ability when done.
  # Used by ConcertoPlugin for rendering hooks, and by use_plugin_ability
  # block above.
  def switch_to_plugin_ability(mod)
    @main_app_ability = @current_ability
    @plugin_abilities = @plugin_abilities || {}
    mod_sym = mod.name.to_sym
    if @plugin_abilities[mod_sym].nil?
      begin
        ability = (mod.name+"::Ability").constantize
      rescue
        ability = nil
      end
      if ability.nil?
        # Presumably this plugin doesn't define its own rules, no biggie
        logger.warn "ConcertoPlugin: use_plugin_ability: "+
          "No Ability found for "+mod.name
      else
        @plugin_abilities[mod_sym] ||= ability.new(current_accessor)
        @current_ability = @plugin_abilities[mod_sym]
      end
    else
      @current_ability = @plugin_abilities[mod_sym]
    end
  end

  # Revert to the main app ability after using a plugin ability
  # (if it was defined).
  # Used by ConcertoPlugin for rendering hooks, and by use_plugin_ability
  # block above.
  def switch_to_main_app_ability
    @current_ability = @main_app_ability # it is okay if this is nil
  end

  # Record and send notification of an activity.
  #
  # @param [ActiveRecord<#create_activity>] ar_instance Instance of the model on which activity
  #   is being tracked; for this to work, its class needs to include PublicActivity::Common.
  # @param [Hash] pa_params Any information you want to send to PublicActivity to be stored in the params column.
  #   This is redundant since you can also include them in the options[:params].
  # @param [Hash] options Options to send to PublicActivity like :key, :action, :owner, and :recipient
  #   (see http://rubydoc.info/gems/public_activity/PublicActivity/Common:create_activity).
  # @return [Model,nil] New activity if created successfully, otherwise nil.
  def process_notification(ar_instance, pa_params, options = {})
    return nil if ar_instance.nil? || !ar_instance.respond_to?('create_activity')

    options[:params] ||= {}
    options[:params].merge!(pa_params) unless pa_params.nil?
    activity = ar_instance.create_activity(options)
    
    # Get the name of the activity mailer by changing the dot to an underscore (eg "submission.update" to "submission_update")
    am_string = activity.key.gsub(".", "_")

    # If ActivityMailer can find a method by the formulated name, pass in the activity (everything we know about what was done)
    if ActivityMailer.respond_to?(am_string) && !options[:recipient].nil? && !options[:owner].nil? && options[:recipient] != options[:owner]
      #fulfilling bamnet's expansive notification ambitions via metaprogramming since 2013
      begin
        ActivityMailer.send(am_string, activity).deliver
      #make an effort to catch all mail-related exceptions after sending the mail - IOError will catch anything for sendmail, SMTP for the rest
      rescue IOError, Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
        Rails.logger.debug "Mail delivery failed at #{Time.now.to_s} for #{options[:recipient]}: #{e.message}"
        ConcertoConfig.first.create_activity action: :system_notification, params: {message: t(:smtp_send_error)}
      rescue OpenSSL::SSL::SSLError => e
        Rails.logger.debug "Mail delivery failed at #{Time.now.to_s} for #{options[:recipient]}: #{e.message} -- might need to disable SSL Verification in settings"
        ConcertoConfig.first.create_activity action: :system_notification, params: {message: t(:smtp_send_error_ssl)}
      end
    end

    activity
  end

  # Expose a instance variable counting the number of pending submissions
  # a user can moderate.  0 indicates no pending submissions.
  # @pending_submissions_count
  def compute_pending_moderation
    @pending_submissions_count = 0
    if user_signed_in?
      feeds = current_user.owned_feeds
      feeds.each do |f|
        @pending_submissions_count += f.submissions_to_moderate.count
      end
    end
  end

  def set_version
    require 'concerto/version'
  end

  def set_locale
    if user_signed_in? && current_user.locale != ""
      session[:locale] = current_user.locale
    end

    I18n.locale = session[:locale] || I18n.default_locale
  end

  #If there are no users defined yet, redirect to create the first admin user
  def check_for_initial_install
    #Don't do anything if a user is logged in
    unless user_signed_in?
      #if the flag set in the seeds file still isn't set to true and there are no users, let's do our thing
      if !User.exists? && !ConcertoConfig[:setup_complete]
        redirect_to new_user_registration_path
      end
    end
  end

  #Don't break for CanCan exceptions; send the user to the front page with a Flash error message
  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json { render json: {error:true, status:403, message: exception.message}, status: :forbidden }
      format.xml{ render xml: {error:true, status:403, message: exception.message}, status: :forbidden }
      format.any {
        redirect_to main_app.root_url, flash: { notice: exception.message }
      }
    end
  end


  # Ensure that any Relative URL Root applied by the webserver is available
  # to engine routing logic. This should not be needed once we go to Rails 4,
  # per Rails ticket #6933
  def apply_relative_root
    Rails.application.routes.default_url_options[:script_name] = ENV['RAILS_RELATIVE_URL_ROOT']
  end

  # Authenticate using the current action and instance variables.
  # If the instance variable is an {Enumerable} or {ActiveRecord::Relation}
  # we remove anything that we cannot? from the array.
  # If the instance variable is a single object, we raise {CanCan::AccessDenied}
  # if we cannot? the object.
  #
  # @param [Hash] opts The options to authenticate with.
  # @option opts [Symbol] action The CanCan action to test.
  # @option opts [Object] object The object we should be testing.
  # @option opts [Boolean] allow_empty (true) If we should allow an empty array.
  # @option opts [Boolean] new_exception (true) Allow the user to the page if they can create
  #   new objects, regardless of the empty status.
  # or raise if empty.
  def auth!(opts = {})
    action_map = {
      'index' => :read,
      'show' => :read,
      'new' => :create,
      'edit' => :update,
      'create' => :create,
      'update' => :update,
      'destroy' => :delete,
    }

    test_action = (opts[:action] || action_map[action_name])
    allow_empty = true
    if !opts[:allow_empty].nil?
      allow_empty = opts[:allow_empty]
    end

    new_exception = true
    if !opts[:new_exception].nil?
      new_exception = opts[:new_exception]
    end

    var_name = controller_name
    if action_name != 'index'
      var_name = controller_name.singularize
    end
    object = (opts[:object] || instance_variable_get("@#{var_name}"))
    object_needs_replacement = false

    unless object.nil?
      if (object.is_a? ActiveRecord::Relation)
        # ActiveRecord::Relation will maintain ties back to the original query.
        # By replacing it with an array, we can make sure that it only ever
        # contains the items which have passed auth!.
        pagination = extract_pagination_from_relation(object)
        object = object.to_a
        object_needs_replacement = true
      end # Now continue as a normal Enumberable
      if (object.is_a? Enumerable)
        object = object.to_a # In case of a non-Array Enumerable
        object.delete_if {|o| cannot?(test_action, o)}
        if new_exception && object.empty?
          # Parent will be Object for Concerto, or the module for Plugins.
          new_parent = self.class.parent
          class_name =  controller_name.singularize.classify
          new_class = new_parent.const_get(class_name) if new_parent.const_defined?(class_name)
          new_object = new_class.new if !new_class.nil?
          return true if can?(:create, new_object)
        end
        if !allow_empty && object.empty?
          fake_cancan = Class.new.extend(CanCan::Ability)
          message ||= fake_cancan.unauthorized_message(test_action, object.class)
          raise CanCan::AccessDenied.new(message, test_action, object.class)
        end
        object = reapply_pagination(object, pagination) unless pagination.nil?
        if object_needs_replacement
          # Certain objects (Relations in particular) can't be authorized
          # by simply modifying them - they need to be replaced with new objects.
          instance_variable_set("@#{var_name}",object) if opts[:object].nil?
          return object if !opts[:object].nil?
        end
      else
        if cannot?(test_action, object)
          fake_cancan = Class.new.extend(CanCan::Ability)
          message ||= fake_cancan.unauthorized_message(test_action, object.class)
          raise CanCan::AccessDenied.new(message, test_action, object.class)
        end
      end
    end
  end

  helper_method :auth!

  # This method allows us to perform authorization on arrays (discarding items
  # based on cancan results) and ensure that any requested pagination is applied
  # to the authorized array.
  # Note we can only help if the relation has not been frozen yet.
  def extract_pagination_from_relation(relation)
    if relation.loaded?
      # Can't do anything once the query has been executed.
      return nil
    elsif relation.singleton_class.include? Kaminari::PageScopeMethods
     # This relation has had Kaminari's .page() method applied
     page = relation.current_page
     per = relation.limit_value
     offset = relation.offset_value
     # Reset the relation to the pre-pagination query as best we can.
     # If Kaminari's padding() method was used, the padding will be
     # applied before auth.
     relation.limit_value = nil
     relation.offset_value = [0,offset-(page-1)*per].max
     return {page: page, per: per}
    else
     # Not paginated, we don't need to do anything.
     return nil
    end
  end

  def reapply_pagination(arr, pagination)
    if pagination.is_a? Hash
      page = pagination[:page]
      per = pagination[:per]
      if page.is_a? Numeric and per.is_a? Numeric
       return Kaminari.paginate_array(arr).page(page).per(per)
      end
    end
    # If there was no pagination, we need to do nothing.
    return arr
  end

  # Cross-Origin Resource Sharing for JS interfaces
  # Browsers are very selective about allowing CORS when Authentication
  # headers are present. They require us to use an origin by name, not *,
  # and to specifically allow authorization credentials (twice).
  def allow_cors
    origin = request.headers['origin']
    headers['Access-Control-Allow-Origin'] = origin || '*'
    headers['Access-Control-Allow-Methods'] = '*'
    headers['Access-Control-Allow-Credentials'] = 'true'
    headers['Access-Control-Allow-Headers'] = 'Authorization'
    headers['Access-Control-Expose-Headers'] = 'ETag, X-Concerto-Frontend-Setup-Key'
  end

  # Redirect the user to the dashboard after signing in.
  def after_sign_in_path_for(resource)
    dashboard_path
  end

  protected

  # Sets the default process notification options along with custom settings.
  #
  # @param [Hash] options Options for the process notification.
  # @return [Hash] The options to pass along.
  def process_notification_options(options = {})
    opts = {}
    opts[:params] = {
      owner_name: current_user.name
    }
    opts[:owner] = current_user
    opts[:action] = action_name
    if options.include?(:params)
      opts[:params].merge!(options[:params])
      options.delete(:params)
    end
    opts.merge!(options)

    # if personal identifying information is to be redacted then wipeout the owner name
    # and member_name
    redact_pii = true # set accordingly from config
    if opts.include?(:params) && redact_pii
      opts[:params].delete(:user_name)  if opts[:params].include?(:user_name)
      opts[:params].delete(:owner_name)  if opts[:params].include?(:owner_name)
      opts[:params].delete(:member_name)  if opts[:params].include?(:member_name)
    end

    opts
  end

end

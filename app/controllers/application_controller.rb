class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_locale
  before_filter :check_for_initial_install
  before_filter :set_version
  before_filter :compute_pending_moderation
  around_filter :user_time_zone, :if => :user_signed_in?
  helper_method :webserver_supports_restart?

  # Current Ability for CanCan authorization
  # This matches CanCan's code but is here to be explicit,
  # since we modify @current_ability below for plugins.
  def current_ability
    if @screen_api
      @current_ability ||= ::Ability.new(current_accessor)
    end
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

  # Call this with a before filter to indicate that the current action
  # should be treated as a Screen API page. On Screen API pages, the
  # current logged-in screen (if there is one) is used instead of the
  # current user. For non-screen API pages, it is impossible for a
  # screen to view the page (though that may change).
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
  
  def user_time_zone(&block)
   Time.use_zone(current_user.time_zone, &block)
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

  def precompile_error_catch
    require 'yaml'
    concerto_base_config = YAML.load_file("./config/concerto.yml")
    if concerto_base_config['compile_production_assets'] == true  
      if File.exist?('public/assets/manifest.yml') == false && Rails.env.production?
        precompile_status = system("env RAILS_ENV=production bundle exec rake assets:precompile")
        if precompile_status == true
          restart_webserver()
        else
          raise "Asset precompilation failed. Please make sure the command rake assets:precompile works."
        end
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
  
  #ar_instance - the Concerto class being passed in; for this to work, its class needs to include PA
  #pa_params - specifically params send to PA to be stored in the params column on the activities 
  #options - right now it only contains the action being performed (CRUD), but anything we don't want to send to PA can go here
  def process_notification(ar_instance, pa_params, options = {})
    return if ar_instance.nil? || !ar_instance.respond_to?('create_activity')
    activity = ar_instance.create_activity(options[:action], :owner => options[:owner], :recipient => options[:recipient], :params => pa_params)
    #form the actionmailer method name by combining the class name with the action being performed (e.g. "submission_update")
    am_string = "#{ar_instance.class.name.downcase}_#{options[:action]}"
    #If ActivityMailer can find a method by the formulated name, pass in the activity (everything we know about what was done)
    if ActivityMailer.respond_to?(am_string)
      #fulfilling bamnet's expansive notification ambitions via metaprogramming since 2013
      begin
        ActivityMailer.send(am_string, activity).deliver
      #make an effort to catch all mail-related exceptions after sending the mail - IOError will catch anything for sendmail, SMTP for the rest
      rescue IOError, Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
        Rails.logger.debug "Mail delivery failed at #{Time.now.to_s} for #{options[:recipient]}: #{e.message}"
        ConcertoConfig.first.create_activity :action => :system_notification, :params => {:message => t(:smtp_send_error)}
      end
    end
  end

  # Expose a instance variable counting the number of pending submissions
  # a user can moderate.  0 indicates no pending submissions.
  # @pending_submissions_count
  def compute_pending_moderation
    @pending_submissions_count = 0
    if user_signed_in?
      feeds = current_user.owned_feeds
      feeds.each do |f|
        @pending_submissions_count += f.submissions.pending.count
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
    redirect_to main_app.root_url, :flash => { :notice => exception.message }
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
      'destroy' => :destroy,
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

    unless object.nil?
      if ((object.is_a? Enumerable) || (object.is_a? ActiveRecord::Relation))
        object.delete_if {|o| cannot?(test_action, o)}
        if new_exception && object.empty?
          # Parent will be Object for Concerto, or the module for Plugins.
          new_parent = self.class.parent
          new_class = new_parent.const_get(controller_name.singularize.classify)
          new_object = new_class.new
          return true if can?(:create, new_object)
        end
        if !allow_empty && object.empty?
          fake_cancan = Class.new.extend(CanCan::Ability)
          message ||= fake_cancan.unauthorized_message(test_action, object.class)
          raise CanCan::AccessDenied.new(message, test_action, object.class)
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
  
  def allow_cors(site='*')
    headers['Access-Control-Allow-Origin'] = site
    headers['Access-Control-Allow-Methods'] = '*'
  end
end

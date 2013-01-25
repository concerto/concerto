class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_locale
  before_filter :check_for_initial_install
  before_filter :set_version
  before_filter :compute_pending_moderation

  # Current Ability for CanCan authorization
  # This matches CanCan's code but is here to be explicit,
  # since we modify @current_ability below for plugins.
  def current_ability
    @current_ability ||= ::Ability.new(current_user)
  end

  def precompile_error_catch
    require 'yaml'
    concerto_base_config = YAML.load_file("./config/concerto.yml")
    if concerto_base_config['compile_production_assets'] == true  
      if File.exist?('public/assets/manifest.yml') == false && Rails.env.production?
        precompile_status = system("bundle exec rake assets:precompile")
        if precompile_status == true
          File.open("tmp/restart.txt", "w") {}
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
        @plugin_abilities[mod_sym] ||= ability.new(current_user)
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
      if ConcertoConfig[:setup_complete] == "false" && User.all.empty?
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
          new_parent = self.class.parent.name
          new_class = new_parent + '::' + controller_name.singularize.classify
          new_object = new_class.constantize.new
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

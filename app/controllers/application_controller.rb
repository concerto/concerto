class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_locale
  before_filter :check_for_initial_install
  before_filter :set_version
  before_filter :compute_pending_moderation

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
    redirect_to root_url, :flash => { :notice => exception.message }
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
  # @option opts [Boolean] allow_empty (true) If we should allow an empty array
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

    var_name = controller_name
    if action_name != 'index'
      var_name = controller_name.singularize
    end
    object = (opts[:object] || instance_variable_get("@#{var_name}"))

    unless object.nil?
      if ((object.is_a? Enumerable) || (object.is_a? ActiveRecord::Relation))
        object.delete_if {|o| cannot?(test_action, o)}
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
  
end

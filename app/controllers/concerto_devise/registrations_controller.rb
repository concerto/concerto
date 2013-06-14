#Overriding the Devise Registrations controller for fun and profit
class ConcertoDevise::RegistrationsController < Devise::RegistrationsController
  prepend_before_filter :require_no_authentication, :only => [ :new, :create, :cancel ]
  prepend_before_filter :authenticate_scope!, :only => [:edit, :update, :destroy]
  rescue_from ActionView::Template::Error, :with => :precompile_error_catch
  before_filter :check_permissions, :only=>[:new, :create]  
  before_filter :configure_permitted_parameters

  def check_permissions
    authorize! :create, User
  end

  # GET /resource/sign_up
  def new
    build_resource({})
    render_registration_form(resource)
  end

  # POST /resource
  def create
    self.resource = build_resource(sign_up_params)
    
    # If there are no users, the first one created will be an admin
    if !User.exists?
      first_user_setup = true
      resource.is_admin = true
      # At first registration, the admin is given the option to 
      # opt-out of error reporting.
    end    

    if resource.save
      if ConcertoConfig["setup_complete"] == false
        ConcertoConfig.set("setup_complete", "true")
        # send_errors option is displayed in the form for first setup only
        ConcertoConfig.set("send_errors", params[:send_errors])
      end

      if first_user_setup == true
        group = Group.find_or_create_by_name(:name => "Concerto Admins")
        Membership.create(:user_id => resource.id, :group_id => group.id, :level => Membership::LEVELS[:leader])
      end
      
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_up(resource_name, resource)
        respond_with resource, :location => after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      respond_with resource
    end
  end

  # GET /resource/edit
  def edit
    render :edit
  end

  # PUT /resource
  # We need to use a copy of the resource because we don't want to change
  # the current user in place.
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    if resource.update_with_password(account_update_params)
      if is_navigational_format?
        flash_key = update_needs_confirmation?(resource, prev_unconfirmed_email) ?
          :update_needs_confirmation : :updated
        set_flash_message :notice, flash_key
      end
      sign_in resource_name, resource, :bypass => true
      respond_with resource, :location => after_update_path_for(resource)
    else
      clean_up_passwords resource
      respond_with resource
    end
  end

  # DELETE /resource
  # Overriden because Devise doesn't account for the possibility
  # that self-destruction would be restricted.
  def destroy
    if resource.destroy
      Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
      set_flash_message :notice, :destroyed if is_navigational_format?
      respond_with_navigational(resource){ redirect_to after_sign_out_path_for(resource_name) }
    else
      # This i18n translation comes from Concerto, not Devise
      flash[:notice] = t(:cannot_delete_last_admin)
    end  
  end

  # Decide whether to render the first admin registration page or simply
  # the plain user registration form.
  def render_registration_form(resource)
    clean_up_passwords resource
    if ConcertoConfig[:setup_complete]
      respond_with resource
    else 
      @concerto_config = ConcertoConfig.new # for send_errors field
      respond_with resource do |format|
        format.html { render "new_first_admin", :layout => "no-topmenu" }
      end
    end
  end

  # Where to redirect the user after registration
  def after_sign_up_path_for(resource)
    if resource.is_a?(User) && resource.is_admin?
      dashboard_path
    else
      root_url
    end
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  def cancel
    expire_session_data_after_sign_in!
    redirect_to new_registration_path(resource_name)
  end

  protected

  def update_needs_confirmation?(resource, previous)
    resource.respond_to?(:pending_reconfirmation?) &&
      resource.pending_reconfirmation? &&
      previous != resource.unconfirmed_email
  end

  # Build a devise resource passing in the session. Useful to move
  # temporary session data to the newly created user.
  def build_resource(hash=nil)
    self.resource = resource_class.new_with_session(hash || {}, session)
  end

  # Signs in a user on sign up. You can overwrite this method in your own
  # RegistrationsController.
  def sign_up(resource_name, resource)
    sign_in(resource_name, resource)
  end

  # The path used after sign up. You need to overwrite this method
  # in your own RegistrationsController.
  def after_sign_up_path_for(resource)
    after_sign_in_path_for(resource)
  end

  # The path used after sign up for inactive accounts. You need to overwrite
  # this method in your own RegistrationsController.
  def after_inactive_sign_up_path_for(resource)
    respond_to?(:root_path) ? root_path : "/"
  end

  # The default url to be used after updating a resource. You need to overwrite
  # this method in your own RegistrationsController.
  def after_update_path_for(resource)
    signed_in_root_path(resource)
  end
  
  #custom fields
  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) do |u|
      u.permit(:first_name, :last_name, :email, :password, :password_confirmation)
    end
    devise_parameter_sanitizer.for(:account_update) do |u|
      u.permit(:first_name, :last_name, :email, :password, :password_confirmation, :current_password)
    end
  end  

  # Authenticates the current scope and gets the current resource from the session.
  def authenticate_scope!
    send(:"authenticate_#{resource_name}!", :force => true)
    self.resource = send(:"current_#{resource_name}")
  end

  def sign_up_params
    devise_parameter_sanitizer.for(:sign_up)
  end

  def account_update_params
    devise_parameter_sanitizer.for(:account_update)
  end
end

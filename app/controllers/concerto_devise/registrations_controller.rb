#Overriding the Devise Registrations controller for fun and profit
class ConcertoDevise::RegistrationsController < Devise::RegistrationsController
  rescue_from ActionView::Template::Error, :with => :precompile_error_catch
  before_filter :check_permissions, :only=>[:new, :create]

  def check_permissions
    authorize! :create, User
  end

  # GET /resource/sign_up
  def new
    resource = build_resource({})
    render_registration_form(resource)
  end

  def create
    build_resource

    # If there are no users, the first one created will be an admin
    if User.all.empty?
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
        sign_in(resource_name, resource)
        respond_with resource, :location => after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      render_registration_form(resource)
    end
  end

  # DELETE /resource
  # Overriden because Devise doesn't account for the possibility
  # that self-destruction would be restricted.
  def destroy
    if resource.destroy
      Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    else
      # This i18n translation comes from Concerto, not Devise
      flash[:notice] = t(:cannot_delete_last_admin)
    end
    respond_with_navigational(resource){ redirect_to after_sign_out_path_for(resource_name) }
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

private

  def resource_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end

end 

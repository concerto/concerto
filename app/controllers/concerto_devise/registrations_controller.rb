#Overriding the Devise Registrations controller for fun and profit
class ConcertoDevise::RegistrationsController < Devise::RegistrationsController
  before_filter :check_permissions, :only=>[:new, :create]

  def check_permissions
    authorize! :create, User
  end

  # GET /resource/sign_up
  def new
    resource = build_resource({})
    @concerto_config = ConcertoConfig.new
    respond_with resource
  end

  def create
    build_resource
    ConcertoConfig.set("send_errors", params[:concerto_config][:send_errors][:value])
    #If there are no users, the first one created will be an admin
    if User.all.empty?
      first_user_setup = true
      #set the first user to be an admin
      resource.is_admin = true
    end
    if resource.save    
      if first_user_setup == true
        ConcertoConfig.set("setup_complete", "true")
        #let's be idempotent here...
        group = Group.find_or_create_by_name(:name => "Concerto Admins")
        #create the membership only after we have the user
        Membership.create(:user_id => resource.id, :group_id => group.id, :level => Membership::LEVELS[:leader])
      end     
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_in(resource_name, resource)
        #respond_with resource, :location => after_sign_up_path_for(resource)
        redirect_to "/dashboard"
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

end 

#Overriding the Devise Registrations controller for fun and profit
class ConcertoDevise::RegistrationsController < Devise::RegistrationsController

  def create
    build_resource
    #If there are no users, the first one created will be an admin
    if User.all.empty?
      resource.is_admin = true
    end
    if resource.save
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
      clean_up_passwords resource
      respond_with resource
    end
  end

end 
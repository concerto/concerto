class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def cas
    cas_hash = request.env["omniauth.auth"]
    user = User.from_omniauth(cas_hash)

    if !user 
    	flash.notice = "Failed to Sign in with CAS"
    	redirect_to "/"
    elsif user.persisted?
    	flash.notice = "Signed in through CAS"
    	sign_in_and_redirect user
    else
    	flash.notice = "Signed in through CAS"
    	session["devise.user_attributes"] = user.attributes
    	redirect_to "/"
    end
  end

end
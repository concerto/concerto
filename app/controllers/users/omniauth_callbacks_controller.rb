class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def openid_connect
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "OpenID Connect") if is_navigational_format?
    else
      # Don't stash the OmniAuth payload in the session here: it carries the
      # id_token JWT and access/refresh tokens (several KB), which overflows the
      # 4KB cookie session and raises CookieOverflow. Nothing reads this value,
      # so we simply send the user to the registration form. See issue #1656.
      redirect_to new_user_registration_url
    end
  end

  def failure
    redirect_to root_path
  end
end

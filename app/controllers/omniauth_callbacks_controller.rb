class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def cas
    cas_hash = request.env["omniauth.auth"]
    render :text => request.env["omniauth.auth"]
  end

end
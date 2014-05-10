#Overriding the Devise Sessions controller for fun and profit
class ConcertoDevise::SessionsController < Devise::SessionsController

  # GET /resource/sign_in
  def new
    redirect_to "/users/auth/cas"
  end
end

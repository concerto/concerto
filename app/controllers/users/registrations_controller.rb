class Users::RegistrationsController < Devise::RegistrationsController
  before_action :ensure_registration_enabled, only: [ :new, :create ]

  private

  def ensure_registration_enabled
    if Setting[:public_registration] == false
      redirect_to new_user_session_path, alert: "Self-registration is currently disabled. Please contact an administrator."
    end
  end
end

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def openid_connect
    auth = request.env["omniauth.auth"]
    @user = User.from_omniauth(auth)

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "OpenID Connect") if is_navigational_format?
    else
      # The provider authenticated the user, but we could not create a local
      # account — almost always because required claims (email, name) were not
      # released. Fail loudly instead of silently bouncing to registration.
      log_provisioning_failure(auth)
      redirect_to new_user_session_path, alert: provisioning_failure_message(auth)
    end
  end

  def failure
    redirect_to root_path
  end

  private

  # Records everything an operator needs to debug a failed provisioning without
  # access to the identity provider: which claims we needed, which claims the
  # provider actually sent, and the resulting validation errors.
  def log_provisioning_failure(auth)
    received = auth.info.to_h.reject { |_, value| value.blank? }.keys.sort
    Rails.logger.warn(
      "[OIDC] Authenticated with provider but could not provision a local user. " \
      "uid=#{auth.uid.inspect} " \
      "missing_claims=#{User.missing_omniauth_claims(auth).inspect} " \
      "received_claims=#{received.inspect} " \
      "validation_errors=#{@user.errors.full_messages.inspect}"
    )
  end

  # Builds a user-facing message that names the missing claims so the person
  # signing in (or their IdP administrator) knows exactly what to fix. Falls
  # back to a generic message when the failure is not a missing-claim problem.
  def provisioning_failure_message(auth)
    missing = User.missing_omniauth_claims(auth)
    return I18n.t("devise.omniauth_callbacks.provisioning_failed_other") if missing.empty?

    I18n.t("devise.omniauth_callbacks.provisioning_failed", claims: missing.to_sentence)
  end
end

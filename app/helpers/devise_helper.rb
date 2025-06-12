module DeviseHelper
  # Checks if the essential OpenID Connect (OIDC) settings are configured.
  #
  # This method verifies that the OIDC issuer, client ID, and client secret
  # have been set in the application's settings.
  #
  # @return [Boolean] `true` if all required OIDC settings are present and not blank.
  def oidc_configured?
    ![ Setting[:oidc_issuer], Setting[:oidc_client_id], Setting[:oidc_client_secret] ].any?(&:blank?)
  end
end

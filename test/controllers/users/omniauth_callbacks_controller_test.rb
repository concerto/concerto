require "test_helper"

class Users::OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
    Rails.application.env_config["devise.mapping"] = Devise.mappings[:user]
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:openid_connect] = nil
    Rails.application.env_config.delete("omniauth.auth")
  end

  # Builds an OmniAuth auth hash whose credentials mirror a real OIDC response:
  # a multi-KB id_token JWT plus access/refresh tokens. Storing this in a cookie
  # session is what previously triggered CookieOverflow (issue #1656).
  def oidc_auth_hash(email:, given_name: "Ada", family_name: "Lovelace")
    OmniAuth::AuthHash.new(
      provider: "openid_connect",
      uid: "oidc-uid-123",
      info: {
        email: email,
        given_name: given_name,
        family_name: family_name
      },
      credentials: {
        token: "access-token",
        refresh_token: "refresh-token",
        id_token: "header.#{"x" * 4000}.signature"
      },
      extra: { raw_info: { sub: "oidc-uid-123" } }
    )
  end

  def stub_callback(auth)
    OmniAuth.config.mock_auth[:openid_connect] = auth
    Rails.application.env_config["omniauth.auth"] = auth
  end

  test "non-persisted user is redirected to registration without overflowing the session cookie" do
    # Blank email fails User validation, so from_omniauth returns an unsaved
    # user and we exercise the branch that used to stash the giant auth hash.
    stub_callback(oidc_auth_hash(email: ""))

    assert_no_difference("User.count") do
      # The old implementation raised ActionDispatch::Cookies::CookieOverflow
      # here because the id_token was written into the cookie session.
      get user_openid_connect_omniauth_callback_url
    end

    assert_redirected_to new_user_registration_url
    assert_nil session["devise.openid_connect_data"]
  end

  test "persisted user is signed in and redirected" do
    stub_callback(oidc_auth_hash(email: "ada-#{Time.now.to_i}@example.com"))

    assert_difference("User.count", 1) do
      get user_openid_connect_omniauth_callback_url
    end

    assert_response :redirect
    assert_nil session["devise.openid_connect_data"]
  end
end

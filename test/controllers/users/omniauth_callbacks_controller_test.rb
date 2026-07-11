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
    Rails.application.env_config.delete("devise.mapping")
  end

  # Builds an OmniAuth auth hash whose credentials mirror a real OIDC response:
  # a multi-KB id_token JWT plus access/refresh tokens. Storing this whole hash
  # in a cookie session is what previously triggered CookieOverflow (issue #1656),
  # so every test drives the callback with a realistically large payload.
  def oidc_auth_hash(email:, given_name: "Ada", family_name: "Lovelace", uid: "oidc-uid-123")
    OmniAuth::AuthHash.new(
      provider: "openid_connect",
      uid: uid,
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
      extra: { raw_info: { sub: uid, groups: [ "x" * 2000 ] } }
    )
  end

  def stub_callback(auth)
    OmniAuth.config.mock_auth[:openid_connect] = auth
    Rails.application.env_config["omniauth.auth"] = auth
  end

  # Hitting an authentication-protected Devise page proves the session actually
  # carries a signed-in user (a redirect to sign-in would mean we're anonymous).
  def assert_signed_in
    get edit_user_registration_url
    assert_response :success
  end

  def assert_signed_out
    get edit_user_registration_url
    assert_redirected_to new_user_session_url
  end

  # --- Successful sign-in ---

  test "provisions a new user from OIDC, signs them in, and redirects" do
    stub_callback(oidc_auth_hash(email: "brand-new@example.com"))

    assert_difference("User.count", 1) do
      get user_openid_connect_omniauth_callback_url
    end

    assert_response :redirect
    assert_signed_in

    user = User.find_by(email: "brand-new@example.com")
    assert_equal "openid_connect", user.provider
    assert_equal "oidc-uid-123", user.uid
  end

  test "sets a success flash message on navigational sign-in" do
    stub_callback(oidc_auth_hash(email: "flash@example.com"))

    get user_openid_connect_omniauth_callback_url

    assert_match(/success/i, flash[:notice])
  end

  test "signs in an existing OIDC user without creating a duplicate" do
    User.create!(
      provider: "openid_connect",
      uid: "oidc-uid-123",
      email: "returning@example.com",
      first_name: "Returning",
      last_name: "User",
      password: "password123"
    )
    stub_callback(oidc_auth_hash(email: "returning@example.com"))

    assert_no_difference("User.count") do
      get user_openid_connect_omniauth_callback_url
    end

    assert_response :redirect
    assert_signed_in
  end

  # --- Non-persisted paths (redirect to registration, no crash) ---

  test "redirects a user with a blank email to registration without overflowing the cookie" do
    # Blank email fails validation, so from_omniauth returns an unsaved user and
    # we exercise the branch that used to stash the giant auth hash. The old code
    # raised ActionDispatch::Cookies::CookieOverflow on this request.
    stub_callback(oidc_auth_hash(email: ""))

    assert_no_difference("User.count") do
      get user_openid_connect_omniauth_callback_url
    end

    assert_redirected_to new_user_registration_url
    assert_nil session["devise.openid_connect_data"], "OIDC payload must not be stashed in the session"
    assert_signed_out
  end

  # --- Failure endpoint ---

  test "an authentication failure redirects to the root path" do
    # OmniAuth routes provider/auth failures (denied consent, invalid state, IdP
    # errors) through the failure action; the user should land home rather than
    # hit an error page or a redirect loop.
    original_on_failure = OmniAuth.config.on_failure
    OmniAuth.config.mock_auth[:openid_connect] = :invalid_credentials
    OmniAuth.config.on_failure = Proc.new { |env| Users::OmniauthCallbacksController.action(:failure).call(env) }

    # In test mode the request phase redirects to the callback, where the
    # invalid mock triggers OmniAuth's failure handling.
    post user_openid_connect_omniauth_authorize_url
    follow_redirect!

    assert_redirected_to root_path
  ensure
    OmniAuth.config.on_failure = original_on_failure
  end
end

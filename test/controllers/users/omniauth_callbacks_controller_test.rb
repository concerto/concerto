require "test_helper"

class Users::OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:openid_connect] = nil
  end

  # Drives the OpenID Connect callback with a mocked auth response, exercising
  # the real provisioning path in the controller and User model.
  def callback_with(info:, uid: "uid-#{SecureRandom.hex(4)}")
    OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new(
      provider: "openid_connect", uid: uid, info: info
    )
    get user_openid_connect_omniauth_callback_path
  end

  test "signs in a user when the provider releases all required claims" do
    assert_difference -> { User.count }, 1 do
      callback_with(info: { email: "grace@uni.edu", given_name: "Grace", family_name: "Hopper" })
    end

    assert_redirected_to root_path
    assert flash[:notice].present?, "expected a success flash"

    user = User.find_by(email: "grace@uni.edu")
    assert_equal "Grace", user.first_name
    assert_equal "Hopper", user.last_name
  end

  test "does not sign in and explains which claims are missing" do
    assert_no_difference -> { User.count } do
      callback_with(info: { given_name: "No", family_name: "Email" }) # no email, as bare CAS returns
    end

    assert_redirected_to new_user_session_path
    assert_match(/didn't share the following required information/, flash[:alert])
    assert_match(/email/, flash[:alert])
  end

  test "logs the received and missing claims when provisioning fails" do
    log = StringIO.new
    original_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(log)

    callback_with(info: { given_name: "No", family_name: "Email", nickname: "noemail" })

    log_output = log.string
    assert_match(/\[OIDC\]/, log_output)
    assert_match(/missing_claims=.*email/, log_output)
    assert_match(/received_claims=/, log_output)
  ensure
    Rails.logger = original_logger
  end
end

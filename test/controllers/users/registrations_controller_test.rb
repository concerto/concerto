require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Ensure we start with registration enabled
    Setting[:public_registration] = true
  end

  teardown do
    # Reset setting after each test
    Setting[:public_registration] = true
  end

  # --- Registration Enabled Tests ---

  test "should get new registration page when registration is enabled" do
    get new_user_registration_url
    assert_response :success
    assert_select "h2", text: /Sign up/i
  end

  test "should allow user creation when registration is enabled" do
    assert_difference("User.count") do
      post user_registration_url, params: {
        user: {
          email: "newuser#{Time.now.to_i}@example.com",
          password: "password123",
          password_confirmation: "password123",
          first_name: "New",
          last_name: "User"
        }
      }
    end
  end

  test "should get new registration page when setting is nil (default)" do
    Setting.find_by(key: "public_registration")&.destroy
    Rails.cache.delete("settings/public_registration")

    get new_user_registration_url
    assert_response :success
  end

  # --- Registration Disabled Tests ---

  test "should redirect from new registration page when registration is disabled" do
    Setting[:public_registration] = false

    get new_user_registration_url
    assert_redirected_to new_user_session_url
    assert_equal "Self-registration is currently disabled. Please contact an administrator.", flash[:alert]
  end

  test "should not allow user creation when registration is disabled" do
    Setting[:public_registration] = false

    assert_no_difference("User.count") do
      post user_registration_url, params: {
        user: {
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to new_user_session_url
  end

  # --- UI Tests ---

  test "should show sign up link on login page when registration is enabled" do
    get new_user_session_url
    assert_response :success
    assert_select "a[href='#{new_user_registration_path}']", text: /Sign up/i
  end

  test "should hide sign up link on login page when registration is disabled" do
    Setting[:public_registration] = false

    get new_user_session_url
    assert_response :success
    assert_select "a[href='#{new_user_registration_path}']", count: 0
  end
end

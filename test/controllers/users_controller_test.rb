require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    @system_admin = users(:system_admin)
  end

  # Authorization tests
  test "signed in users can view user list" do
    sign_in @user
    get users_url
    assert_response :success
  end

  test "unauthenticated users cannot view user list" do
    get users_url
    assert_redirected_to new_user_session_path
  end

  test "signed in users can view user profiles" do
    sign_in @user
    get user_url(@user)
    assert_response :success
  end

  test "unauthenticated users cannot view user profiles" do
    get user_url(@user)
    assert_redirected_to new_user_session_path
  end

  # Index functionality tests
  test "should show user list with all users" do
    sign_in @user
    get users_url
    assert_response :success
    assert_select "h1", text: "All Users"
    assert_select "table tbody tr", minimum: 1
  end

  # Show functionality tests
  test "should show user profile with display name" do
    sign_in @user
    user = users(:admin)
    get user_url(user)
    assert_response :success
    assert_select "h1", text: user.display_name
  end

  test "should show message when user has no content" do
    sign_in @user
    user = users(:regular)
    get user_url(user)
    assert_response :success
    assert_select "h3", text: "No content yet"
  end
end

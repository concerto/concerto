require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    @system_admin = users(:system_admin)
  end

  # Authorization tests
  test "signed in users can view user profiles" do
    sign_in @user
    get user_url(@user)
    assert_response :success
  end

  test "unauthenticated users cannot view user profiles" do
    get user_url(@user)
    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  # Original functionality tests
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

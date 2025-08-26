require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should show user profile with display name" do
    user = users(:admin)
    get user_url(user)
    assert_response :success
    assert_select "h1", text: "#{user.display_name} User Profile"
  end

  test "should show message when user has no content" do
    user = users(:regular)
    get user_url(user)
    assert_response :success
    assert_select "div", text: "This user has not uploaded any content."
  end
end

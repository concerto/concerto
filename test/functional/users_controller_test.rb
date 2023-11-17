require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "blank and regular user cannot list all users" do
    get :index, params: {}
    assert_login_failure

    sign_in users(:katie)
    get :index, params: {}
    assert_response :redirect
  end

  test "admin can list all users" do
    sign_in users(:admin)
    get :index, params: {}
    assert_response :success
    assert_select "tr", 1+4 # 1 header row + 4 users.
  end

  test "user can see other users" do
    sign_in users(:katie)
    get :show, params: { :id => users(:kristen).id }
    assert_response :success
    assert_equal users(:kristen), assigns(:user)
  end

end

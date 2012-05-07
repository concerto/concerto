require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "blank and regular user cannot list all users" do
    get :index
    assert_response :redirect
    assert !assigns(:users)

    sign_in users(:katie)
    get :index
    assert_response :redirect
    assert !assigns(:users)
  end

  test "admin can list all users" do
    sign_in users(:admin)
    get :index
    assert_response :success
    assert assigns(:users)
  end

  test "user can see other users" do
    sign_in users(:katie)
    get :show, :id => users(:kristen).id
    assert_response :success
    assert_equal assigns(:user), users(:kristen)
  end

end

require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should not create user" do #A duplicate user is against the rules, and I don't think the world can handle 2 katies
    assert_no_difference('User.count') do
      post :create, :user => users(:katie).attributes
    end

    #assert_redirected_to user_path(assigns(:user))
  end

  test "should show user" do
    get :show, :id => users(:katie).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => users(:katie).to_param
    assert_response :success
  end

  test "should update user" do
    put :update, :id => users(:katie).to_param, :user => users(:katie).attributes
    assert_redirected_to user_path(assigns(:user))
  end

  test "should destroy user" do
    assert_difference('User.count', -1) do
      delete :destroy, :id => users(:katie).to_param
    end

    assert_redirected_to users_path
  end
end

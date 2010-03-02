require 'test_helper'

class GroupsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:groups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should not create group" do
    assert_no_difference('Group.count') do
      post :create, :group => groups(:one).attributes
    end

    #assert_redirected_to group_path(assigns(:group))
  end

  test "should show group" do
    get :show, :id => groups(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => groups(:one).to_param
    assert_response :success
  end

  test "should update group" do
    put :update, :id => groups(:one).to_param, :group => groups(:one).attributes
    assert_redirected_to group_path(assigns(:group))
  end

  test "should destroy group" do
    assert_difference('Group.count', -1) do
      delete :destroy, :id => groups(:one).to_param
    end

    assert_redirected_to groups_path
  end
end

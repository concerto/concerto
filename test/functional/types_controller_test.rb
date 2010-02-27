require 'test_helper'

class TypesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  #test "should create type" do
  #  assert_difference('Type.count') do
  #    post :create, :type => types(:text).attributes
  #  end

  #  assert_redirected_to type_path(assigns(:type))
  #end

  test "should show type" do
    get :show, :id => types(:text).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => types(:text).to_param
    assert_response :success
  end

  #test "should update type" do
  #  put :update, :id => types(:text).to_param, :type => types(:text).attributes
  #  assert_redirected_to type_path(assigns(:type))
  #end

  test "should destroy type" do
    assert_difference('Type.count', -1) do
      delete :destroy, :id => types(:text).to_param
    end

    assert_redirected_to types_path
  end
end

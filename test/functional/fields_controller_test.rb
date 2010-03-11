require 'test_helper'

class FieldsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:fields)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create field" do
    assert_difference('Field.count') do
      post :create, :field => fields(:one).attributes
    end

    assert_redirected_to field_path(assigns(:field))
  end

  test "should show field" do
    get :show, :id => fields(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => fields(:one).to_param
    assert_response :success
  end

  test "should update field" do
    put :update, :id => fields(:one).to_param, :field => fields(:one).attributes
    assert_redirected_to field_path(assigns(:field))
  end

  test "should destroy field" do
    assert_difference('Field.count', -1) do
      delete :destroy, :id => fields(:one).to_param
    end

    assert_redirected_to fields_path
  end
end

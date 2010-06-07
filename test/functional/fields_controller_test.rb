require 'test_helper'

class FieldsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index, :type_id => types(:ticker).id
    assert_response :success
    assert_not_nil assigns(:fields)
  end

  test "should get new" do
    get :new, :type_id => types(:ticker).id
    assert_response :success
  end

  #test "should create field" do
  #  assert_difference('Field.count') do
  #    post :create, :type_id => types(:ticker).id, :field => fields(:one).attributes
  #  end
  #
  #  assert_redirected_to field_path(assigns(:field))
  #end

  test "should show field" do
    get :show, :type_id => types(:ticker).id, :id => fields(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => fields(:one).to_param, :type_id => types(:ticker).id
    assert_response :success
  end

  #test "should update field" do
  #  put :update, :id => fields(:one).to_param, :field => fields(:one).attributes, :type_id => types(:ticker).id
  #  assert_redirected_to field_path(assigns(:field))
  #end

  #test "should destroy field" do
  #  assert_difference('Field.count', -1) do
  #    delete :destroy, :type_id => types(:ticker).id, :id => fields(:one).to_param
  #  end
  #
  #  assert_redirected_to fields_path
  #end
end

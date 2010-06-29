require 'test_helper'

class FieldsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index, :kind_id => kinds(:ticker).id
    assert_response :success
    assert_not_nil assigns(:fields)
  end

  test "should get new" do
    get :new, :kind_id => kinds(:ticker).id
    assert_response :success
  end

  test "should create field" do
    assert_difference('Field.count') do
      post :create, :kind_id => kinds(:ticker).id, :field => fields(:one).attributes
    end
  
    assert_redirected_to kind_field_path(kinds(:ticker), assigns(:field))
  end

  test "should show field" do
    get :show, :kind_id => kinds(:ticker).id, :id => fields(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => fields(:one).to_param, :kind_id => kinds(:ticker).id
    assert_response :success
  end

  test "should update field" do
    put :update, :id => fields(:one).to_param, :field => fields(:one).attributes, :kind_id => kinds(:ticker).id
    assert_redirected_to kind_field_path(kinds(:ticker), assigns(:field))
  end

  test "should destroy field" do
    assert_difference('Field.count', -1) do
      delete :destroy, :kind_id => kinds(:ticker).id, :id => fields(:one).to_param
    end
  
    assert_redirected_to kind_fields_path(kinds(:ticker))
  end
end

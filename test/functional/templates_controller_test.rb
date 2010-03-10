require 'test_helper'

class TemplatesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:templates)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create template" do
    assert_difference('Template.count') do
      post :create, :template => templates(:one).attributes
    end

    assert_redirected_to template_path(assigns(:template))
  end

  test "should show template" do
    get :show, :id => templates(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => templates(:one).to_param
    assert_response :success
  end

  test "should update template" do
    put :update, :id => templates(:one).to_param, :template => templates(:one).attributes
    assert_redirected_to template_path(assigns(:template))
  end

  test "should destroy template" do
    assert_difference('Template.count', -1) do
      delete :destroy, :id => templates(:one).to_param
    end

    assert_redirected_to templates_path
  end
end

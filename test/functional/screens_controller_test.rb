require 'test_helper'

class ScreensControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:screens)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create screen" do
    assert_difference('Screen.count') do
      post :create, :screen => screens(:one).attributes
    end

    assert_redirected_to screen_path(assigns(:screen))
  end

  test "should show screen" do
    get :show, :id => screens(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => screens(:one).to_param
    assert_response :success
  end

  test "should update screen" do
    put :update, :id => screens(:one).to_param, :screen => screens(:one).attributes
    assert_redirected_to screen_path(assigns(:screen))
  end

  test "should destroy screen" do
    assert_difference('Screen.count', -1) do
      delete :destroy, :id => screens(:one).to_param
    end

    assert_redirected_to screens_path
  end
end

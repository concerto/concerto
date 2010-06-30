require 'test_helper'

class ContentsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:contents)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create content" do
    assert_difference('Content.count') do
      post :create, :ticker => contents(:sample_ticker).attributes, :type => "Ticker" 
    end

    assert_redirected_to content_path(assigns(:content))
  end

  test "should show content" do
    get :show, :id => contents(:sample_ticker).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => contents(:sample_ticker).to_param
    assert_response :success
  end

  test "should update content" do
    put :update, :id => contents(:sample_ticker).to_param, :ticker => contents(:sample_ticker).attributes
    assert_redirected_to content_path(assigns(:content))
  end

  test "should destroy content" do
    assert_difference('Content.count', -1) do
      delete :destroy, :id => contents(:sample_ticker).to_param
    end

    assert_redirected_to contents_path
  end
end

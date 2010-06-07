require 'test_helper'

class FeedsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:feeds)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create feed" do
    assert_difference('Feed.count') do
      post :create, :feed => {:name => "Test feed", :group => groups(:wtg)}
    end

    assert_redirected_to feed_path(assigns(:feed))
  end

  test "should show feed" do
    get :show, :id => feeds(:service).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => feeds(:service).to_param
    assert_response :success
  end

  test "should update feed" do
    put :update, :id => feeds(:service).to_param, :feed => feeds(:service).attributes
    assert_redirected_to feed_path(assigns(:feed))
  end

  test "should destroy feed" do
    assert_difference('Feed.count', -1) do
      delete :destroy, :id => feeds(:service).to_param
    end

    assert_redirected_to feeds_path
  end
end

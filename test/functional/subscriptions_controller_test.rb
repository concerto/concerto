require 'test_helper'

class SubscriptionsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index, :screen_id => screens(:one).to_param
    assert_response :success
    assert_not_nil assigns(:subscriptions)
  end

  test "should get new" do
    get :new, :screen_id => screens(:one).to_param
    assert_response :success
  end

  test "should not create subscription" do
    assert_no_difference('Subscription.count') do
      post :create, :screen_id => screens(:one).to_param, :subscription => subscriptions(:one).attributes
    end
  
    #assert_redirected_to screen_subscription_path(screens(:one), assigns(:subscription))
  end

  test "should show subscription" do
    get :show, :id => subscriptions(:one).to_param, :screen_id => screens(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => subscriptions(:one).to_param, :screen_id => screens(:one).to_param
    assert_response :success
  end

  test "should update subscription" do
    put :update, :screen_id => screens(:one).to_param, :id => subscriptions(:one).to_param, :subscription => subscriptions(:one).attributes
    assert_redirected_to screen_subscription_path(screens(:one), assigns(:subscription))
  end

  test "should destroy subscription" do
    assert_difference('Subscription.count', -1) do
      delete :destroy, :screen_id => screens(:one).to_param, :id => subscriptions(:one).to_param
    end
  
    assert_redirected_to screen_subscriptions_path(screens(:one))
  end
end

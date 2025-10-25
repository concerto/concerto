require "test_helper"

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subscription = subscriptions(:one)
    @screen = screens(:one)
  end

  test "should get index" do
    get screen_subscriptions_url(@screen)
    assert_response :success
  end

  test "should create subscription" do
    assert_difference("Subscription.count") do
      # Use different field/feed combination that doesn't conflict with existing subscriptions
      post screen_subscriptions_url(@screen), params: { subscription: { feed_id: feeds(:two).id, field_id: fields(:ticker).id } }
    end

    assert_redirected_to screen_subscriptions_url(Subscription.last.screen)
  end

  test "should destroy subscription" do
    assert_difference("Subscription.count", -1) do
      delete screen_subscription_url(@subscription.screen, @subscription)
    end

    assert_redirected_to screen_subscriptions_url(@subscription.screen)
  end
end

require "test_helper"

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subscription = subscriptions(:one)
    @screen = screens(:one)
    sign_in users(:regular) # Regular user is a member of the screen's group
  end

  teardown do
    sign_out :user
  end

  test "should get index" do
    get screen_subscriptions_url(@screen)
    assert_response :success
  end

  test "should get index when not signed in" do
    sign_out :user
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

  test "should not create subscription when not authorized" do
    sign_in users(:non_member)
    assert_no_difference("Subscription.count") do
      post screen_subscriptions_url(@screen),
           params: { subscription: { feed_id: feeds(:two).id, field_id: fields(:ticker).id } },
           headers: { "Referer" => screen_subscriptions_url(@screen) }
    end
    assert_response :redirect
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should destroy subscription" do
    assert_difference("Subscription.count", -1) do
      delete screen_subscription_url(@subscription.screen, @subscription)
    end

    assert_redirected_to screen_subscriptions_url(@subscription.screen)
  end

  test "should not destroy subscription when not authorized" do
    sign_in users(:non_member)
    assert_no_difference("Subscription.count") do
      delete screen_subscription_url(@subscription.screen, @subscription),
             headers: { "Referer" => screen_subscriptions_url(@subscription.screen) }
    end
    assert_response :redirect
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should update subscription weight" do
    original_weight = @subscription.weight
    new_weight = 8

    patch screen_subscription_url(@screen, @subscription),
          params: { subscription: { weight: new_weight } }

    assert_redirected_to screen_subscriptions_url(@screen)
    assert_equal new_weight, @subscription.reload.weight
    assert_not_equal original_weight, @subscription.reload.weight
  end

  test "should not update subscription when not authorized" do
    sign_in users(:non_member)
    original_weight = @subscription.weight

    patch screen_subscription_url(@screen, @subscription),
          params: { subscription: { weight: 8 } },
          headers: { "Referer" => screen_subscriptions_url(@screen) }

    assert_response :redirect
    assert_equal "You are not authorized to perform this action.", flash[:alert]
    assert_equal original_weight, @subscription.reload.weight
  end

  test "should not update subscription with invalid weight" do
    original_weight = @subscription.weight

    patch screen_subscription_url(@screen, @subscription),
          params: { subscription: { weight: 99 } }

    assert_response :redirect
    assert_match(/Failed to update subscription/, flash[:alert])
    assert_equal original_weight, @subscription.reload.weight
  end

  test "should not update subscription with weight below minimum" do
    original_weight = @subscription.weight

    patch screen_subscription_url(@screen, @subscription),
          params: { subscription: { weight: 0 } }

    assert_response :redirect
    assert_match(/Failed to update subscription/, flash[:alert])
    assert_equal original_weight, @subscription.reload.weight
  end
end

require "application_system_test_case"

class SubscriptionsTest < ApplicationSystemTestCase
  setup do
    @subscription = subscriptions(:one)
    @screen = screens(:one)
  end

  test "visiting the index" do
    visit screen_subscriptions_url(@screen)
    assert_selector "h1", text: "Subscriptions"
  end

  #  test "should create subscription" do
  #    visit screen_subscriptions_url(@screen)
  #    click_on "New subscription"
  #
  #    select @subscription.feed.name, from: "Feed"
  #    select @subscription.field.name, from: "Field"
  #    click_on "Create Subscription"
  #
  #    assert_text "Subscription was successfully created"
  #    click_on "Back"
  #  end

  #  test "should destroy Subscription" do
  #    visit screen_subscription_url(@screen)
  #    click_on "Destroy this subscription", match: :first
  #
  #    assert_text "Subscription was successfully destroyed"
  #  end
end

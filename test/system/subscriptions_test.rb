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

  test "should create subscription" do
    visit screen_subscriptions_url(@screen)

    within("#" + dom_id(positions(:two))) do
      select @subscription.feed.name, from: "Feed"
      click_on "Create Subscription"
    end

    assert_text "#{positions(:two).field.name} field subscription to #{@subscription.feed.name} feed was successfully created"
  end

  test "should destroy Subscription" do
    visit screen_subscriptions_url(@screen)

    subscription = subscriptions(:one_sidebar_rss)
    within("#" + dom_id(subscription)) do
      click_on "Unsubscribe"
    end

    assert_text "#{subscription.field.name} field subscription to #{subscription.feed.name} feed was successfully destroyed"
  end
end

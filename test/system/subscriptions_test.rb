require "application_system_test_case"

class SubscriptionsTest < ApplicationSystemTestCase
  setup do
    @subscription = subscriptions(:one)
    @screen = screens(:one)
  end

  test "visiting the index" do
    visit screen_subscriptions_url(@screen)
    assert_selector "h1", text: "Feed Subscriptions"
  end

  test "should create subscription" do
    visit screen_subscriptions_url(@screen)

    within("#" + dom_id(positions(:two_sidebar))) do
      select @subscription.feed.name, from: "Add Feed"
      click_on "Add"
    end

    assert_text "#{positions(:two_sidebar).field.name} field subscription to #{@subscription.feed.name} feed was successfully created"
  end

  test "should destroy Subscription" do
    visit screen_subscriptions_url(@screen)

    subscription = subscriptions(:one_sidebar_rss)
    within("#" + dom_id(subscription)) do
      accept_confirm do
        click_on "Remove"
      end
    end

    assert_text "#{subscription.field.name} field subscription to #{subscription.feed.name} feed was successfully destroyed"
  end
end

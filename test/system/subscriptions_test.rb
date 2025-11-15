require "application_system_test_case"

class SubscriptionsTest < ApplicationSystemTestCase
  setup do
    @subscription = subscriptions(:one)
    @screen = screens(:one)
    sign_in users(:regular) # Regular user is a member of the screen's group
  end

  test "visiting the index" do
    visit screen_subscriptions_url(@screen)
    assert_selector "h1", text: "Feed Subscriptions"
  end

  test "visiting the index when not signed in" do
    sign_out :user
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

  test "should not show create form when not authorized" do
    sign_in users(:non_member)
    visit screen_subscriptions_url(@screen)

    # Form should not be present for non-members
    assert_no_selector "select[name='subscription[feed_id]']"
  end

  test "should destroy Subscription" do
    visit screen_subscriptions_url(@screen)

    subscription = subscriptions(:one_sidebar_rss)
    within("#" + dom_id(subscription)) do
      accept_confirm do
        click_on "Remove"
      end
    end

    assert_text "#{subscription.field.name} field subscription to #{subscription.feed.name} feed was successfully removed"
  end

  test "should not show delete button when not authorized" do
    sign_in users(:non_member)
    visit screen_subscriptions_url(@screen)

    subscription = subscriptions(:one_sidebar_rss)
    # Delete button should not be present for non-members
    within("#" + dom_id(subscription)) do
      assert_no_button "Remove"
    end
  end
end

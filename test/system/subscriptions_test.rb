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

  test "should show weight slider for authorized users" do
    visit screen_subscriptions_url(@screen)

    subscription = subscriptions(:one)
    within("#" + dom_id(subscription)) do
      # Weight slider should be present
      assert_selector "input[type='range'][data-weight-slider-target='slider']"
      # Low and High labels should be present
      assert_text "Low"
      assert_text "High"
    end
  end

  test "should not show weight slider for unauthorized users" do
    sign_in users(:non_member)
    visit screen_subscriptions_url(@screen)

    subscription = subscriptions(:one)
    within("#" + dom_id(subscription)) do
      # Weight slider should not be present for non-members
      assert_no_selector "input[type='range'][data-weight-slider-target='slider']"
    end
  end

  test "should update subscription weight via slider" do
    visit screen_subscriptions_url(@screen)

    subscription = subscriptions(:one)
    original_weight = subscription.weight

    within("#" + dom_id(subscription)) do
      # Find the slider
      slider = find("input[type='range'][data-weight-slider-target='slider']")

      # Move slider to position 5 (High - weight 8)
      slider.set(5)
    end

    # Wait for Turbo to complete the update
    assert_text "Subscription weight was successfully updated"

    # Verify the weight was actually updated in the database
    assert_equal 8, subscription.reload.weight
    assert_not_equal original_weight, subscription.reload.weight
  end
end

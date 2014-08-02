require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase
  test "weight names" do
    assert_equal "very rarely", subscriptions(:one).weight_name
  end

  test "screen cannot unassociated" do
    subscription = Subscription.new(:field_id => fields(:two).id,
                                    :feed_id => feeds(:service).id,
                                    :weight => Subscription::WEIGHTS[:rarely])
    assert subscription.invalid?, "Subscription screen is blank"
    subscription.screen_id = 0
    assert subscription.invalid?, "Subscription screen is unassociated"
    subscription.screen = screens(:two)
    assert subscription.valid?, subscription.errors.to_yaml
  end

  test "field cannot unassociated" do
    subscription = Subscription.new(:screen_id => screens(:two).id,
                                    :feed_id => feeds(:service).id,
                                    :weight => Subscription::WEIGHTS[:rarely])
    assert subscription.invalid?, "Subscription field is blank"
    subscription.field_id = 0
    assert subscription.invalid?, "Subscription field is unassociated"
    subscription.field = fields(:two)
    assert subscription.valid?, subscription.errors.to_yaml
  end

  test "feed cannot unassociated" do
    subscription = Subscription.new(:screen_id => screens(:two).id,
                                    :field_id => fields(:two).id,
                                    :weight => Subscription::WEIGHTS[:rarely])
    assert subscription.invalid?, "Subscription feed is blank"
    subscription.feed_id = 0
    assert subscription.invalid?, "Subscription feed is unassociated"
    subscription.feed = feeds(:service)
    assert subscription.valid?, subscription.errors.to_yaml
  end

  test "feed cannot be duplicated" do
    subscription = Subscription.new(:screen_id => screens(:one).id,
                                    :field_id => fields(:one).id,
                                    :feed_id => feeds(:service).id,
                                    :weight => Subscription::WEIGHTS[:rarely])
    assert subscription.invalid?, "Duplicate subscription"
    subscription.feed = feeds(:boring_announcements)
    assert subscription.valid?, subscription.errors.to_yaml
  end
end

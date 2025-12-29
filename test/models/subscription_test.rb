require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  setup do
    @subscription = subscriptions(:one)
  end

  test "subscriptions have content" do
    assert_equal @subscription.contents.to_set, Set[rich_texts(:plain_richtext), graphics(:two), rich_texts(:html_richtext), rich_texts(:active_ticker_text)]
  end

  test "weight defaults to 5" do
    subscription = Subscription.new(
      screen: screens(:one),
      field: fields(:main),
      feed: feeds(:one)
    )
    subscription.save!
    assert_equal 5, subscription.weight
  end

  test "accepts weight of 1" do
    subscription = Subscription.new(
      screen: screens(:two),
      field: fields(:ticker),
      feed: feeds(:one),
      weight: 1
    )
    assert subscription.valid?
  end

  test "accepts weight of 10" do
    subscription = Subscription.new(
      screen: screens(:two),
      field: fields(:ticker),
      feed: feeds(:one),
      weight: 10
    )
    assert subscription.valid?
  end

  test "rejects weight of 0" do
    subscription = Subscription.new(
      screen: screens(:two),
      field: fields(:ticker),
      feed: feeds(:one),
      weight: 0
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:weight], "must be in 1..10"
  end

  test "rejects weight of 11" do
    subscription = Subscription.new(
      screen: screens(:two),
      field: fields(:ticker),
      feed: feeds(:one),
      weight: 11
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:weight], "must be in 1..10"
  end

  test "rejects negative weight" do
    subscription = Subscription.new(
      screen: screens(:two),
      field: fields(:ticker),
      feed: feeds(:one),
      weight: -1
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:weight], "must be in 1..10"
  end

  test "rejects non-integer weight" do
    subscription = Subscription.new(
      screen: screens(:two),
      field: fields(:ticker),
      feed: feeds(:one),
      weight: 5.5
    )
    assert_not subscription.valid?
    assert_includes subscription.errors[:weight], "must be an integer"
  end
end

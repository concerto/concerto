require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  setup do
    @subscription = subscriptions(:one)
  end

  test "subscriptions have content" do
    assert_equal @subscription.contents.to_set, Set[rich_texts(:plain_richtext), graphics(:two)]
  end
end

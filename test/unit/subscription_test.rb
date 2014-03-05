require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase
  test "weight names" do
    assert_equal "very rarely", subscriptions(:one).weight_name
  end
end

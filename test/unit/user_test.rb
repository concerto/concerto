require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    @katie = users(:katie)
    @karen = users(:karen)
    @kristen = users(:kristen)
  end

  test "supporting groups" do
    membership = memberships(:karen_wtg)
    feed_levels = [:all, :submissions, :none]
    feed_levels.each do |level|
      membership.perms[:feed] = level
      membership.save

      groups = @karen.supporting_groups(:feed, [level])
      assert_equal groups, [groups(:wtg)]
    end

    no_groups = @katie.supporting_groups(:feed, feed_levels)
    assert_equal no_groups, []
  end
end

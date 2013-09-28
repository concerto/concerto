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
      assert_equal [groups(:wtg)], groups
    end

    no_groups = @katie.supporting_groups(:feed, feed_levels)
    assert_equal [], no_groups
  end

  test "cannot delete user that owns a screen" do
    s = screens(:one)
    screen = Screen.new(s.attributes)
    screen.owner = @katie
    screen.save
    assert_raises(ActiveRecord::DeleteRestrictionError) do
      @katie.destroy
    end
  end
end

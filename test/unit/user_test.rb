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

  test "in_group?" do
    assert @karen.in_group?(groups(:wtg))
    assert !@karen.in_group?(groups(:rpitv))
  end

  test "cannot delete user that owns a screen" do
    assert !@katie.is_deletable?
    assert @karen.is_deletable?

    assert_raises(ActiveRecord::DeleteRestrictionError) do
      @katie.destroy
    end
  end

  test "cannot delete last admin" do
    assert !users(:admin).destroy
    assert users(:karen).destroy
  end

  test "owned feeds" do
    assert @katie.owned_feeds.include?(feeds(:service))
    assert !@karen.owned_feeds.include?(feeds(:service))
  end

  test "auto confirm" do
    ConcertoConfig.set :confirmable, false
    assert_equal ConcertoConfig[:confirmable], false
    bob = User.create({
      :first_name => 'Bob',
      :last_name => 'Rowe',
      :email => 'bob@rowebot.com',
      :password => 'bubkisbubkis'
    })

    assert_equal Date.new(1824, 11, 5), bob.confirmed_at.to_date
  end
end

require 'test_helper'

class UserFeedAbilityTest < ActiveSupport::TestCase
  def setup
    @service = feeds(:service)
    @secret = feeds(:secret_announcements)
  end

  test "Anyone can read viewable feed" do
    ability = Ability.new(User.new)
    assert ability.can?(:read, @service)
  end

  test "Anyone cannot read nonviewable feed" do
    ability = Ability.new(User.new)
    assert ability.cannot?(:read, @secret)
  end

  test "Group member can read nonviewable feed" do
    ability = Ability.new(users(:katie))
    assert ability.can?(:read, @secret)
  end

  test "Non Group member cannot read nonviewable feed" do
    ability = Ability.new(users(:kristen))
    assert ability.cannot?(:read, @secret)
  end

  test "Only group leaders can delete / update feed" do
    ability = Ability.new(users(:katie))
    assert ability.can?(:update, @service)
    assert ability.can?(:delete, @service)

    ability = Ability.new(users(:kristen))
    assert ability.cannot?(:update, @service)
    assert ability.cannot?(:delete, @service)

    ability = Ability.new(User.new)
    assert ability.cannot?(:update, @service)
    assert ability.cannot?(:delete, @service)

    membership = memberships(:karen_wtg)
    membership.perms[:feed] = :all
    membership.save
    ability = Ability.new(users(:karen))
    assert ability.can?(:update, @service)
    assert ability.can?(:delete, @service)

    [:none, :submissions].each do |p|
      membership.perms[:feed] = p
      membership.save
      ability = Ability.new(users(:karen))
      assert ability.cannot?(:update, @service)
      assert ability.cannot?(:delete, @service)
    end
  end

  test "Group leaders and some supporters can create feeds" do
    ability = Ability.new(users(:katie))
    assert ability.can?(:create, Feed)
    can_feed = Feed.new(:group_id => groups(:wtg).id)
    assert ability.can?(:create, can_feed)
    cannot_feed = Feed.new(:group_id => groups(:rpitv).id)
    assert ability.cannot?(:create, cannot_feed)

    membership = memberships(:karen_wtg)
    membership.perms[:feed] = :all
    membership.save
    ability = Ability.new(users(:karen))
    assert ability.can?(:create, Feed)
    assert ability.can?(:create, can_feed)
    assert ability.cannot?(:create, cannot_feed)

    [:none, :submissions].each do |p|
      membership.perms[:feed] = p
      membership.save
      ability = Ability.new(users(:karen))
      assert ability.cannot?(:create, Feed)
      assert ability.cannot?(:create, can_feed)
      assert ability.cannot?(:create, cannot_feed)
    end
  end

  test "Admin can read all feeds" do
    ability = Ability.new(users(:admin))
    assert ability.can?(:create, Feed)
    assert ability.can?(:read, Feed)
    assert ability.can?(:submit_content, Feed)
    assert ability.can?(:update, Feed)
    assert ability.can?(:destroy, Feed)
  end

  test "Submission creation implies feed submit permission" do
    User.find_each do |user|
      ability = Ability.new(user)
      Feed.find_each do |feed|
        assert_equal ability.can?(:create, Submission.new(:feed => feed)), ability.can?(:submit_content, feed)
      end
    end
  end

end


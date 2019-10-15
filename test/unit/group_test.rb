require 'test_helper'

class GroupTest < ActiveSupport::TestCase
  #Test for duplicate names
  test "name cannot be duplicated" do
    g = groups(:wtg)
    group = Group.new({:name => g.name})
    assert_equal g.name, group.name, "Names are set equal"
    assert !group.valid?, "Names can't be equal"
    group.name = "Fooasdasdasda"
    assert group.valid?, "Unique name is OK"
  end

  #Test has_member?
  test "group has member?" do
    g = groups(:wtg)
    assert g.has_member?(users(:katie)), "Katie is in WTG"
    assert !g.has_member?(users(:kristen)), "Kristen is not in the WTG"
  end

  test "moderators returns list of moderators for the group" do
    g = groups(:wtg)
    assert g.moderators.include?(memberships(:katie_wtg)), "Katie is a moderator"
    assert !g.moderators.include?(memberships(:karen_wtg)), "Karen is not a moderator"
  end

  test "user has permission" do
    g = groups(:wtg)
    u = users(:karen)
    feed_levels = [:all, :submissions, :none]

    membership = memberships(:karen_wtg)
    feed_levels.each do |level|
      membership.perms[:feed] = level
      membership.save

      assert g.user_has_permissions?(u, :regular, :feed, [level])
      assert g.user_has_permissions?(u, :regular, :feed, [:all, level])
    end
    assert !g.user_has_permissions?(u, :regular, :screen, [:all, :subscriptions])
  end

  test "sole leader can't resign leadership" do
    assert !groups(:wtg).can_resign_leadership?(memberships(:katie_wtg))
  end

  test "non-leader can resign leadership" do
    assert groups(:wtg).can_resign_leadership?(memberships(:karen_wtg))
  end

  test "can delete if group owns nothing" do
    assert groups(:unused).is_deletable?

    assert !groups(:wtg).is_deletable?
    Feed.delete_all
    Screen.delete_all
    assert groups(:wtg).is_deletable?
  end

  test "can't delete if group owns screens" do
    Feed.delete_all
    assert !groups(:wtg).is_deletable?
  end

  test "can't delete if group owns feeds" do
    Screen.delete_all
    assert !groups(:wtg).is_deletable?
  end

  test "creating a group with a new leader" do
    u = users(:karen)
    g = Group.create({:name => 'test group with leader', :new_leader => u.id})

    assert g.leaders.include?(u)
  end

  test "users not in group" do
    g = groups(:wtg)
    u = g.users_not_in_group

    assert u.count == 2
    assert u.include?(users(:admin))
    assert u.include?(users(:kristen))
  end

  test "run the update membership callbacks" do
    g = groups(:wtg)
    u = users(:kristen)

    assert !g.has_member?(u)
    m = Membership.new({:group => g, :user => u, :level => Membership::LEVELS[:regular]})
    g.memberships << m
    g.update_membership_perms

    g = Group.where(:name => groups(:wtg).name).first
    assert g.has_member?(u)
  end
end

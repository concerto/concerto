require 'test_helper'

class UserMembershipAbilityTest < ActiveSupport::TestCase

  test "Only leaders are publically readable" do
    ability = Ability.new(users(:kristen))
    assert ability.can?(:read, memberships(:katie_wtg))
    assert ability.cannot?(:read, memberships(:katie_rpitv))    
  end

  test "Regular users can only create pending for themselves" do
    kristen = users(:kristen)
    wtg = groups(:wtg)
    ability = Ability.new(kristen)
    m = Membership.new(:user => kristen, :group => wtg)
    #The default level is pending
    assert ability.can?(:create, m)
    
    m.level = Membership::LEVELS[:pending]
    assert ability.can?(:create, m)

    m.level = Membership::LEVELS[:regular]
    assert ability.cannot?(:create, m)

    m.level = Membership::LEVELS[:leader]
    assert ability.cannot?(:create, m)

    m.level = Membership::LEVELS[:denied]
    assert ability.cannot?(:create, m)

    m.level = Membership::LEVELS[:pending]
    m.user = users(:katie)
    assert ability.cannot?(:create, m)
  end

  test "Group leaders can do anything" do
    kristen = users(:kristen)
    wtg = groups(:wtg)
    ability = Ability.new(users(:katie))
    m = Membership.new(:user => kristen, :group => wtg)
    #The default level is pending
    assert ability.can?(:create, m)
    assert ability.can?(:update, m)
    assert ability.can?(:delete, m)

    m.level = Membership::LEVELS[:pending]
    assert ability.can?(:create, m)
    assert ability.can?(:update, m)
    assert ability.can?(:delete, m)

    m.level = Membership::LEVELS[:regular]
    assert ability.can?(:create, m)
    assert ability.can?(:update, m)
    assert ability.can?(:delete, m)

    m.level = Membership::LEVELS[:leader]
    assert ability.can?(:create, m)
    assert ability.can?(:update, m)
    assert ability.can?(:delete, m)

    m.level = Membership::LEVELS[:denied]
    assert ability.can?(:create, m)
    assert ability.can?(:update, m)
    assert ability.can?(:delete, m)
  end

  test "Users can delete their own memberships" do
    ability = Ability.new(users(:katie))
    ability.can?(:destroy, memberships(:katie_rpitv))

    ability = Ability.new(users(:kristen))
    ability.can?(:destroy, memberships(:katie_rpitv))
  end

  test "Group members can read approved members" do
    ability = Ability.new(users(:katie))
    membership = Membership.new(:group => groups(:rpitv), :level => Membership::LEVELS[:regular])
    ability.can?(:read, membership)

    ability = Ability.new(users(:kristen))
    ability.cannot?(:read, membership)
  end

  test "Group members cannot read pending users" do
    ability = Ability.new(users(:katie))
    membership = Membership.new(:group => groups(:rpitv), :level => Membership::LEVELS[:pending])
    ability.cannot?(:read, membership)

    ability = Ability.new(users(:kristen))
    ability.cannot?(:read, membership)
  end

  test "Group members cannot read denied users" do
    ability = Ability.new(users(:katie))
    membership = Membership.new(:group => groups(:rpitv), :level => Membership::LEVELS[:denied])
    ability.cannot?(:read, membership)

    ability = Ability.new(users(:kristen))
    ability.cannot?(:read, membership)
  end

end

require 'test_helper'

class UserScreenAbilityTest < ActiveSupport::TestCase
  def setup
    @sgs = screens(:two)
    @kt = screens(:one)
    @rpitv = screens(:rpitv)
  end

  test "Screens can only be created by admins (by default)" do
    ability = Ability.new(users(:katie))
    assert ability.cannot?(:create, Screen.new)
  end

  test "Screens cannot be created by unsaved users" do
    ability = Ability.new(User.new)
    assert ability.cannot?(:create, Screen.new)
  end

  test "Users can sometimes create screen they own" do
    ConcertoConfig.set(:allow_user_screen_creation, true)
    ability = Ability.new(users(:katie))
    screen = Screen.new
    assert ability.cannot?(:create, screen)
    screen.owner = users(:katie)
    assert ability.can?(:create, screen)
    screen.owner = users(:kristen)
    assert ability.cannot?(:create, screen)
  end

  test "Users can sometimes create screens for their groups" do
    ConcertoConfig.set(:allow_user_screen_creation, true)
    ability = Ability.new(users(:katie))
    screen = Screen.new
    assert ability.cannot?(:create, screen)
    screen.owner = groups(:wtg)
    assert ability.can?(:create, screen)
    ability = Ability.new(users(:kristen))
    assert ability.cannot?(:create, screen)

    membership = memberships(:karen_wtg)
    membership.perms[:screen] = :all
    membership.save
    ability = Ability.new(users(:karen))
    assert ability.can?(:create, screen)
    membership.perms[:screen] = :subscriptions
    membership.save
    assert ability.cannot?(:create, screen)
  end

  test "Anyone can read public screens" do
    ability = Ability.new(User.new)
    assert ability.can?(:read, @sgs)
  end

  test "Unauthenticated users cannot read private screens" do
    ability = Ability.new(User.new)
    assert ability.cannot?(:read, @kt)
    assert ability.cannot?(:read, @rpitv)
  end

  test "Non members cannot read private screens" do
    ability = Ability.new(users(:kristen))
    assert ability.cannot?(:read, @kt)
    assert ability.cannot?(:read, @rpitv)
  end

  test "Owning user can read private screen" do
    ability = Ability.new(users(:katie))
    assert ability.can?(:read, @kt)
  end

  test "Member of owning group can read private screen" do
    ability = Ability.new(users(:katie))
    assert ability.can?(:read, @rpitv)
  end

  test "Owning user can update and delete screen" do
    ability = Ability.new(users(:katie))
    assert ability.can?(:update, @kt)
    assert ability.can?(:delete, @kt)

    ability = Ability.new(users(:kristen))
    assert ability.cannot?(:update, @kt)
    assert ability.cannot?(:delete, @kt)
  end

  test "Leaders of a group can update and delete screen" do
    ability = Ability.new(users(:katie))
    assert ability.can?(:update, @sgs)
    assert ability.can?(:delete, @sgs)

    ability = Ability.new(users(:kristen))
    assert ability.cannot?(:update, @sgs)
    assert ability.cannot?(:delete, @sgs)

    membership = memberships(:karen_wtg)
    membership.perms[:screen] = :all
    membership.save
    ability = Ability.new(users(:karen))
    assert ability.can?(:update, @sgs)
    assert ability.can?(:delete, @sgs)

    [:none, :subscriptions].each do |p|
      membership.perms[:screen] = p
      membership.save
      ability = Ability.new(users(:karen))
      assert ability.cannot?(:update, @sgs)
      assert ability.cannot?(:delete, @sgs)
    end
  end

  test "Regular group  members cannot update or delete a screen" do
    ability = Ability.new(users(:katie))
    assert ability.cannot?(:update, @rpitv)
    assert ability.cannot?(:delete, @rpitv)
  end
end


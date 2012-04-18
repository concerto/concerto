require 'test_helper'

class UserGroupAbilityTest < ActiveSupport::TestCase
  def setup
    @wtg = groups(:wtg)
    @rpitv = groups(:rpitv)
  end

  test "Group members can read the group" do
    ability = Ability.new(users(:katie))
    assert ability.can?(:read, @rpitv)
  end

  test "Non members cannot read group" do
    ability = Ability.new(users(:kristen))
    assert ability.cannot?(:read, @rpitv)
  end

  test "Only group leaders can update group" do
    ability = Ability.new(users(:katie))
    assert ability.can?(:update, @wtg)

    ability = Ability.new(users(:kristen))
    assert ability.cannot?(:update, @wtg)

    ability = Ability.new(User.new)
    assert ability.cannot?(:update, @wtg)
  end

  test "No one can delete a group" do
    ability = Ability.new(users(:katie))
    assert ability.cannot?(:delete, @wtg)

    ability = Ability.new(users(:kristen))
    assert ability.cannot?(:delete, @wtg)

    ability = Ability.new(User.new)
    assert ability.cannot?(:delete, @wtg)
  end
end


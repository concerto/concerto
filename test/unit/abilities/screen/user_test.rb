require 'test_helper'

class ScreenUserAbilityTest < ActiveSupport::TestCase

  def setup
    @admin = users(:admin)
    @katie = users(:katie)
    @kristen = users(:kristen)
  end

  test "screens can read users" do
    s = screens(:one)
    ability = Ability.new(s)
    assert ability.can?(:read, users(:kristen))
  end

  test "new screens cannot read private users" do
    ability = Ability.new(Screen.new)
    assert ability.cannot?(:read, users(:karen))
  end
end

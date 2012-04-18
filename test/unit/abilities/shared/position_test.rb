require 'test_helper'

class SharedPositionAbilityTest < ActiveSupport::TestCase
  def setup
    @user = users(:kristen)
    @screen = screens(:one)
    @position = positions(:one)
  end

  test "anyone can read positions" do
    [@user, @screen].each do |thing|
      ability = Ability.new(thing)
      assert ability.can?(:read, @position)
    end
  end

  test "no one can update / delete positions" do
    [@user, @screen].each do |thing|
      ability = Ability.new(thing)
      assert ability.cannot?(:update, @position)
      assert ability.cannot?(:delete, @position)
    end
  end
end


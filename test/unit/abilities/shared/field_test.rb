require 'test_helper'

class SharedFieldAbilityTest < ActiveSupport::TestCase
  def setup
    @user = users(:kristen)
    @screen = screens(:one)
    @field = fields(:one)
  end

  test "anyone can read fields" do
    [@user, @screen].each do |thing|
      ability = Ability.new(thing)
      assert ability.can?(:read, @field)
    end
  end

  test "no one can update / delete fields" do
    [@user, @screen].each do |thing|
      ability = Ability.new(thing)
      assert ability.cannot?(:update, @field)
      assert ability.cannot?(:delete, @field)
    end
  end
end


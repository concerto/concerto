require 'test_helper'

class SharedTemplateAbilityTest < ActiveSupport::TestCase
  def setup
    @user = users(:kristen)
    @screen = screens(:one)
    @template = templates(:one)
  end

  test "anyone can read public templates" do
    [@user, @screen].each do |thing|
      ability = Ability.new(thing)
      assert ability.can?(:read, @template)
    end
  end

  test "noone can read public templates" do
    template = templates(:hidden)
    [@user, @screen].each do |thing|
      ability = Ability.new(thing)
      assert ability.cannot?(:read, template)
    end
  end

  test "no one can update / delete templates" do
    [@user, @screen].each do |thing|
      ability = Ability.new(thing)
      assert ability.cannot?(:update, @template)
      assert ability.cannot?(:delete, @template)
    end
  end
end


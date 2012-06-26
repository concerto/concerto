require 'test_helper'

class UserSubscriptionAbilityTest < ActiveSupport::TestCase
  def setup
    @katie = users(:katie)
    @kristen = users(:kristen)
    @feed = feeds(:service)
    @kt_screen = screens(:one)
    @wtg_screen = screens(:two)
    @subscription = Subscription.new(:feed => @feed)
  end

  test "Screen user owner all access" do
    ability = Ability.new(@katie)
    assert ability.can?(:create, Subscription)

    abilities = [:update, :delete, :read]
    @subscription.screen = @kt_screen
    abilities.each do |action|
      assert ability.can?(action, @subscription)
    end

    ability = Ability.new(@kristen)
    abilities.each do |action|
      assert ability.cannot?(action, @subscription)
    end
  end

  test "Screen group owner all access" do
    ability = Ability.new(@katie)
    assert ability.can?(:create, @subscription)

    abilities = [:update, :delete, :read]
    @subscription.screen = @wtg_screen
    abilities.each do |action|
      assert ability.can?(action, @subscription)
    end

    ability = Ability.new(@kristen)
    abilities.each do |action|
      assert ability.cannot?(action, @subscription)
    end
  end
end


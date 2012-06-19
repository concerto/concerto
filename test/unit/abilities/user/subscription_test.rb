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
    abilities = [:update, :delete, :read]
    ability = Ability.new(@katie)
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
    abilities = [:update, :delete, :read]
    ability = Ability.new(@katie)
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


require 'test_helper'

class UserSubscriptionAbilityTest < ActiveSupport::TestCase
  def setup
    @katie = users(:katie)
    @kristen = users(:kristen)
    @feed = feeds(:service)
    @kt_screen = screens(:one)
    @wtg_screen = screens(:two)
    @subscription = Subscription.new(feed: @feed)
  end

  test "Screen user owner all access" do
    ability = Ability.new(@katie)
    @subscription.screen = @kt_screen
    assert ability.can?(:create, @subscription)

    abilities = [:update, :delete, :read]
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
    @subscription.screen = @wtg_screen
    assert ability.can?(:create, @subscription)

    abilities = [:update, :delete, :read]
    abilities.each do |action|
      assert ability.can?(action, @subscription)
    end

    ability = Ability.new(@kristen)
    abilities.each do |action|
      assert ability.cannot?(action, @subscription)
    end

    membership = memberships(:karen_wtg)
    membership.perms[:screen] = :none
    membership.save
    ability = Ability.new(users(:karen))
    abilities.each do |action|
      assert ability.cannot?(action, @subscription)
    end

    [:subscriptions, :all].each do |p|
      membership.perms[:screen] = p
      membership.save
      ability = Ability.new(users(:karen))
      abilities.each do |action|
        assert ability.can?(action, @subscription)
      end
    end

  end
end


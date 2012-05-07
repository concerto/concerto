require 'test_helper'

class UserUserAbilityTest < ActiveSupport::TestCase

  def setup
    @admin = users(:admin)
    @katie = users(:katie)
    @kristen = users(:kristen)
  end

  test "admin users can do anything to users" do
    ability = Ability.new(@admin)
    assert ability.can?(:create, User)
    assert ability.can?(:read, @kristen)
    assert ability.can?(:update, @kristen)
    assert ability.can?(:destroy, User.new)
  end

  test "regular users can only read and update themselves" do
    user = @kristen
    ability = Ability.new(user)
    assert ability.can?(:read, @kristen)
    assert ability.can?(:update, @kristen)

    # Don't let users delete themselves ATM.
    # We need to think about the reprecussions of this
    assert ability.cannot?(:destroy, @kristen)

    assert ability.cannot?(:create, User)
    assert ability.cannot?(:update, @katie)
    assert ability.cannot?(:destroy, @katie)

    # Actually, let users see each other
    assert ability.can?(:read, @katie)
  end

  test "regular users cannot list all users" do
    user = @kristen
    ability = Ability.new(user)
    assert ability.cannot?(:list, User)

    ability = Ability.new(@admin)
    assert ability.can?(:list, User)
  end

  test "new users can only sign up" do
    ability = Ability.new(User.new)
    assert ability.can?(:create, User)
    assert ability.cannot?(:read, @katie)
    assert ability.cannot?(:update, @katie)
    assert ability.cannot?(:destroy, @katie)
  end
end

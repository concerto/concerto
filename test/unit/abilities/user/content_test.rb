require 'test_helper'

class UserContentAbilityTest < ActiveSupport::TestCase
  test "Content can only be created by real users" do
    ability = Ability.new(users(:katie))
    assert ability.can?(:create, Content)
  end

  test "Content cannot be created by unsaved users" do
    ability = Ability.new(User.new)
    assert ability.cannot?(:create, Content)
  end

  test "Content can only be updated by the submitter" do
    ability = Ability.new(users(:katie))
    content = contents(:sample_ticker)
    assert ability.can?(:update, content)

    ability = Ability.new(users(:kristen))
    assert ability.cannot?(:update, content)
  end

  test "Content can only be deleted by the submitter" do
    ability = Ability.new(users(:katie))
    content = contents(:sample_ticker)
    assert ability.can?(:delete, content)

    ability = Ability.new(users(:kristen))
    assert ability.cannot?(:delete, content)
  end
end

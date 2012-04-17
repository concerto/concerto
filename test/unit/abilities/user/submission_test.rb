require 'test_helper'

class UserSubmissionAbilityTest < ActiveSupport::TestCase
  def setup
    @katie = users(:katie)
    @kristen = users(:kristen)
    @wtg = feeds(:service)
    @rpitv = feeds(:secret_announcements)
    @submission = Submission.new
  end

  test "Submissions cannot be created by unsaved users" do
    ability = Ability.new(User.new)
    @submission.feed = @wtg
    assert ability.cannot?(:create, @submission)
  end

  test "Submissions can be created to public feeds" do
    ability = Ability.new(@kristen)
    @submission.feed = @wtg
    assert ability.can?(:create, @submission)
  end

  test "Submissions can be created on private feeds by members" do
    ability = Ability.new(@katie)
    @submission.feed = @rpitv
    assert ability.can?(:create, @submission)
  end

  test "Submissions cannot be created to private feeds by non members" do
    ability = Ability.new(@kristen)
    @submission.feed = @rpitv
    assert ability.cannot?(:create, @submission)
  end
end


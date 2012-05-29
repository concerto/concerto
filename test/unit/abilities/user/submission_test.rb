require 'test_helper'

class UserSubmissionAbilityTest < ActiveSupport::TestCase
  def setup
    @katie = users(:katie)
    @kristen = users(:kristen)
    @wtg = feeds(:service)
    @rpitv = feeds(:secret_announcements)
    @submission = Submission.new
  end

  test "Approved submission can be read on public feed" do
    users = [User.new, @katie, @kristen]
    users.each do |user|
      ability = Ability.new(user)
      @submission.feed = @wtg
      @submission.moderation_flag = true
      assert ability.can?(:read, @submission), "Failing for #{user.name}"
    end
  end

  test "Denied and pending submissions cannot be read on public feed" do
    users = [User.new, @kristen]
    users.each do |user|
      ability = Ability.new(user)
      @submission.feed = @wtg
      [false, nil].each do |flag|
        @submission.moderation_flag = flag
        assert ability.cannot?(:read, @submission), "Failing for #{user.name}"
      end
    end
  end

  test "Denied and pending submission can be read by feed moderator" do
    ability = Ability.new(@katie)
    @submission.feed = @wtg
    [false, nil].each do |flag|
      @submission.moderation_flag = flag
      assert ability.can?(:read, @submission)
    end
  end

  test "Submission cannot be read on private feed" do
    users = [User.new, @kristen]
    users.each do |user|
      [true, false, nil].each do |flag|
        ability = Ability.new(user)
        @submission.feed = @rpitv
        @submission.moderation_flag = flag
        assert ability.cannot?(:read, @submission), "Failing u:#{user.name}, f:#{flag}!"
      end
    end
  end

  test "Approved submission can be read on private feed by group member" do
    ability = Ability.new(@katie)
    @submission.feed = @rpitv
    @submission.moderation_flag = true
    assert ability.can?(:read, @submission)
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

  test "Submissions can be modified by moderator" do
    ability = Ability.new(@katie)
    content = Content.new(:user => users(:admin))
    @submission.content = content
    @submission.feed = feeds(:sleepy_announcements)

    assert ability.can?(:update, @submission)
  end

  test "Submissions cannot be deleted by moderator" do
    ability = Ability.new(@katie)
    content = Content.new(:user => users(:admin))
    @submission.content = content
    @submission.feed = feeds(:sleepy_announcements)

    assert ability.cannot?(:delete, @submission)
  end

  test "Content owner can only read and delete submission" do
    content = Content.new(:user => @kristen)
    @submission.content = content
    @submission.feed = @rpitv

    ability = Ability.new(@kristen)
    assert ability.can?(:read, @submission)
    assert ability.cannot?(:update, @submission)
    assert ability.can?(:delete, @submission)

    ability = Ability.new(@katie)
    assert ability.cannot?(:read, @submission)
    assert ability.cannot?(:update, @submission)
    assert ability.cannot?(:delete, @submission)
  end
end


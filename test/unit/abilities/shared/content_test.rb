require 'test_helper'

class SharedContentAbilityTest < ActiveSupport::TestCase
  def setup
    @content = contents(:old_ticker)
    @bad_content = contents(:sample_ticker)
    @user = User.new
    @screen = Screen.new
  end

  test "anyone can read content approved on 1 feed" do
    # Deny the content on 1 feed
    @content.submissions.create(:feed => feeds(:sleepy_announcements), :moderation_flag => false)

    [@user, @screen].each do |thing|
      ability = Ability.new(thing)
      assert ability.can?(:read, @content), "Failure with #{thing}."
    end
  end

  test "no one can read unapproved content" do
    [@screen, @user, @screen].each do |thing|
      ability = Ability.new(thing)
      assert ability.cannot?(:read, @bad_content), "Failure with #{thing}."
    end
  end
end


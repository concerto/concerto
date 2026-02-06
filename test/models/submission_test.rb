require "test_helper"

class SubmissionTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @non_member = users(:non_member)
    @feed = feeds(:one)  # belongs to feed_one_owners group
    @content = rich_texts(:plain_richtext)
  end

  test "moderation_status enum values" do
    submission = Submission.new(content: @content, feed: @feed)
    assert submission.pending?

    submission.moderation_status = :approved
    assert submission.approved?

    submission.moderation_status = :rejected
    assert submission.rejected?
  end

  test "auto-approves submission when feed auto-approves" do
    rss_feed = rss_feeds(:test_rssfeed)
    content = RichText.create!(name: "Test", text: "Test", user: @non_member, duration: 10, config: { render_as: "plaintext" })
    submission = Submission.create!(content: content, feed: rss_feed)

    assert submission.approved?
    assert_not_nil submission.moderated_at
  end

  test "auto-approves submission when user is member of feed's group" do
    # admin is a member of feed_one_owners (owns feed one)
    content = RichText.create!(name: "Test", text: "Test", user: @user, duration: 10, config: { render_as: "plaintext" })
    submission = Submission.create!(content: content, feed: @feed)

    assert submission.approved?
  end

  test "creates pending submission when user is not member of feed's group" do
    content = RichText.create!(name: "Test", text: "Test", user: @non_member, duration: 10, config: { render_as: "plaintext" })
    submission = Submission.create!(content: content, feed: @feed)

    assert submission.pending?
    assert_nil submission.moderated_at
  end

  test "moderate! approves submission" do
    content = RichText.create!(name: "Test", text: "Test", user: @non_member, duration: 10, config: { render_as: "plaintext" })
    submission = Submission.create!(content: content, feed: @feed)

    assert submission.pending?

    submission.moderate!(status: :approved, moderator: @user, reason: "Looks good")

    assert submission.approved?
    assert_equal @user, submission.moderator
    assert_equal "Looks good", submission.moderation_reason
    assert_not_nil submission.moderated_at
  end

  test "moderate! rejects submission" do
    content = RichText.create!(name: "Test", text: "Test", user: @non_member, duration: 10, config: { render_as: "plaintext" })
    submission = Submission.create!(content: content, feed: @feed)

    submission.moderate!(status: :rejected, moderator: @user, reason: "Not appropriate")

    assert submission.rejected?
    assert_equal @user, submission.moderator
    assert_equal "Not appropriate", submission.moderation_reason
  end

  test "should_auto_approve? returns true for RSS feeds" do
    rss_feed = rss_feeds(:test_rssfeed)
    submission = Submission.new(content: @content, feed: rss_feed)

    assert submission.should_auto_approve?
  end

  test "should_auto_approve? returns true for group members" do
    content = RichText.create!(name: "Test", text: "Test", user: @user, duration: 10, config: { render_as: "plaintext" })
    submission = Submission.new(content: content, feed: @feed)

    assert submission.should_auto_approve?
  end

  test "should_auto_approve? returns false for non-members" do
    content = RichText.create!(name: "Test", text: "Test", user: @non_member, duration: 10, config: { render_as: "plaintext" })
    submission = Submission.new(content: content, feed: @feed)

    refute submission.should_auto_approve?
  end

  test "reevaluate_moderation! resets human-moderated submissions for non-members" do
    content = RichText.create!(name: "Test", text: "Test", user: @non_member, duration: 10, config: { render_as: "plaintext" })
    submission = Submission.create!(content: content, feed: @feed)

    # Human moderator approves
    submission.moderate!(status: :approved, moderator: @user, reason: "OK")
    assert submission.approved?
    assert_equal @user, submission.moderator

    # Re-evaluate (e.g., content edited) - should reset because substantive changes require re-review
    submission.reevaluate_moderation!

    # Should be pending again because user is not a member of the feed's group
    assert submission.pending?
    assert_nil submission.moderator
    assert_nil submission.moderation_reason
  end

  test "reevaluate_moderation! resets auto-approved submissions for non-members" do
    content = RichText.create!(name: "Test", text: "Test", user: @non_member, duration: 10, config: { render_as: "plaintext" })
    rss_feed = rss_feeds(:test_rssfeed)  # auto-approves
    submission = Submission.create!(content: content, feed: rss_feed)

    assert submission.approved?
    assert_nil submission.moderator  # was auto-approved

    # Move to a non-auto-approving feed and re-evaluate
    submission.update!(feed: @feed)
    submission.reevaluate_moderation!

    # Should now be pending because user is not a member of the new feed's group
    assert submission.pending?
  end

  test "reevaluate_moderation! keeps auto-approved status for members" do
    content = RichText.create!(name: "Test", text: "Test", user: @user, duration: 10, config: { render_as: "plaintext" })
    submission = Submission.create!(content: content, feed: @feed)

    assert submission.approved?
    assert_nil submission.moderator  # was auto-approved

    submission.reevaluate_moderation!

    # Should still be approved because user is a member
    assert submission.approved?
  end

  test "reevaluate_moderation! clears moderator data when auto-approving" do
    content = RichText.create!(name: "Test", text: "Test", user: @user, duration: 10, config: { render_as: "plaintext" })
    submission = Submission.create!(content: content, feed: @feed)

    # Manually moderate (e.g., system admin reviewing)
    submission.moderate!(status: :approved, moderator: users(:system_admin), reason: "Checked")
    assert_equal users(:system_admin), submission.moderator
    assert_equal "Checked", submission.moderation_reason

    # Re-evaluate - should auto-approve and clear moderator data
    submission.reevaluate_moderation!

    assert submission.approved?
    assert_nil submission.moderator, "Moderator should be cleared for auto-approval"
    assert_nil submission.moderation_reason, "Moderation reason should be cleared"
  end
end

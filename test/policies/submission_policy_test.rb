require "test_helper"

class SubmissionPolicyTest < ActiveSupport::TestCase
  setup do
    @system_admin_user = users(:system_admin)
    @content_owner = users(:admin)  # Owner of plain_richtext
    @other_user = users(:regular)
    @non_member = users(:non_member)
    @submission = submissions(:three)  # Links plain_richtext (owned by admin) to feed two
  end

  test "scope returns all submissions for everyone" do
    resolved_scope = SubmissionPolicy::Scope.new(nil, Submission.all).resolve
    assert_equal Submission.all.to_a, resolved_scope.to_a

    resolved_scope = SubmissionPolicy::Scope.new(@other_user, Submission.all).resolve
    assert_equal Submission.all.to_a, resolved_scope.to_a
  end

  test "index? is permitted for everyone" do
    assert SubmissionPolicy.new(nil, Submission).index?
    assert SubmissionPolicy.new(@non_member, Submission).index?
  end

  # Moderation-specific tests
  test "moderate? is permitted for feed group member" do
    assert SubmissionPolicy.new(@content_owner, @submission).moderate?
  end

  test "moderate? is denied for non-member" do
    refute SubmissionPolicy.new(@non_member, @submission).moderate?
  end

  test "moderate? is denied for anonymous users" do
    refute SubmissionPolicy.new(nil, @submission).moderate?
  end

  test "pending? is permitted for signed-in users" do
    assert SubmissionPolicy.new(@content_owner, Submission).pending?
    assert SubmissionPolicy.new(@other_user, Submission).pending?
  end

  test "pending? is denied for anonymous users" do
    refute SubmissionPolicy.new(nil, Submission).pending?
  end

  test "ModerationScope returns submissions in user's groups" do
    # admin is a member of feed_one_owners and feed_two_owners
    scope = SubmissionPolicy::ModerationScope.new(@content_owner, Submission.all).resolve
    assert scope.exists?(id: @submission.id)
  end

  test "ModerationScope returns nothing for non-member" do
    scope = SubmissionPolicy::ModerationScope.new(@non_member, Submission.all).resolve
    assert_empty scope
  end

  test "permitted_attributes_for_moderation" do
    policy = SubmissionPolicy.new(@content_owner, @submission)
    assert_equal [ :moderation_status, :moderation_reason ], policy.permitted_attributes_for_moderation
  end

  # visible_submissions tests
  test "visible_submissions returns only approved submissions for anonymous user" do
    content = rich_texts(:plain_richtext)
    visible = SubmissionPolicy.visible_submissions(nil, content)
    assert visible.all?(&:approved?)
    refute visible.any?(&:pending?)
  end

  test "visible_submissions returns all submissions for content owner" do
    content = rich_texts(:plain_richtext)
    visible = SubmissionPolicy.visible_submissions(@content_owner, content)
    assert_includes visible, submissions(:three)
    assert_includes visible, submissions(:pending_submission)
  end

  test "visible_submissions returns all submissions for system admin" do
    content = rich_texts(:plain_richtext)
    visible = SubmissionPolicy.visible_submissions(@system_admin_user, content)
    assert_includes visible, submissions(:three)
    assert_includes visible, submissions(:pending_submission)
  end

  test "visible_submissions returns approved plus own group pending for feed group member" do
    content = rich_texts(:plain_richtext)
    # regular user is a member of feed_one_owners but NOT feed_two_owners
    visible = SubmissionPolicy.visible_submissions(@other_user, content)
    # Should see approved submission (three, on feed two) and pending (on feed one, their group)
    assert_includes visible, submissions(:three)
    assert_includes visible, submissions(:pending_submission)
  end

  test "visible_submissions returns only approved for non-member" do
    content = rich_texts(:plain_richtext)
    visible = SubmissionPolicy.visible_submissions(@non_member, content)
    assert_includes visible, submissions(:three)
    refute_includes visible, submissions(:pending_submission)
  end

  test "visible_submissions returns nothing when content has only pending submissions and user is non-member" do
    content = rich_texts(:plain_richtext)
    # Remove approved submissions for this content, leaving only pending
    submissions(:three).update!(moderation_status: :pending)
    visible = SubmissionPolicy.visible_submissions(@non_member, content)
    assert_empty visible
  end

  # show_reason? tests
  test "show_reason? returns true for content owner" do
    submission = submissions(:rejected_submission)
    assert SubmissionPolicy.new(@content_owner, submission).show_reason?
  end

  test "show_reason? returns true for system admin" do
    submission = submissions(:rejected_submission)
    assert SubmissionPolicy.new(@system_admin_user, submission).show_reason?
  end

  test "show_reason? returns true for feed group member" do
    submission = submissions(:rejected_submission)
    # regular user is a member of feed_one_owners, and rejected_submission is on feed one
    assert SubmissionPolicy.new(@other_user, submission).show_reason?
  end

  test "show_reason? returns false for non-member" do
    submission = submissions(:rejected_submission)
    refute SubmissionPolicy.new(@non_member, submission).show_reason?
  end

  test "show_reason? returns false for anonymous user" do
    submission = submissions(:rejected_submission)
    refute SubmissionPolicy.new(nil, submission).show_reason?
  end
end

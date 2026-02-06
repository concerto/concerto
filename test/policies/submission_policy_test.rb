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
    policy = SubmissionPolicy.new(@member, @submission)
    assert_equal [ :moderation_status, :moderation_reason ], policy.permitted_attributes_for_moderation
  end
end

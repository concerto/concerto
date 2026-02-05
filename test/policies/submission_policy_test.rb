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

  test "show? is permitted for everyone" do
    assert SubmissionPolicy.new(nil, @submission).show?
    assert SubmissionPolicy.new(@non_member, @submission).show?
  end

  test "new? is permitted for system admin" do
    new_submission = Submission.new(content: @submission.content)
    assert SubmissionPolicy.new(@system_admin_user, new_submission).new?
  end

  test "new? is permitted for content owner" do
    new_submission = Submission.new(content: @submission.content)
    assert SubmissionPolicy.new(@content_owner, new_submission).new?
  end

  test "new? is denied for non-owner" do
    new_submission = Submission.new(content: @submission.content)
    refute SubmissionPolicy.new(@other_user, new_submission).new?
  end

  test "new? is denied for anonymous users" do
    new_submission = Submission.new(content: @submission.content)
    refute SubmissionPolicy.new(nil, new_submission).new?
  end

  test "create? is permitted for system admin" do
    new_submission = Submission.new(content: @submission.content)
    assert SubmissionPolicy.new(@system_admin_user, new_submission).create?
  end

  test "create? is permitted for content owner" do
    new_submission = Submission.new(content: @submission.content)
    assert SubmissionPolicy.new(@content_owner, new_submission).create?
  end

  test "create? is denied for non-owner" do
    new_submission = Submission.new(content: @submission.content)
    refute SubmissionPolicy.new(@other_user, new_submission).create?
  end

  test "create? is denied for anonymous users" do
    new_submission = Submission.new(content: @submission.content)
    refute SubmissionPolicy.new(nil, new_submission).create?
  end

  test "edit? is permitted for system admin" do
    assert SubmissionPolicy.new(@system_admin_user, @submission).edit?
  end

  test "edit? is permitted for feed group member (can moderate)" do
    # admin user is a member of feed_two_owners, which owns feed two
    assert SubmissionPolicy.new(@content_owner, @submission).edit?
  end

  test "edit? is denied for non-member of feed group" do
    refute SubmissionPolicy.new(@non_member, @submission).edit?
  end

  test "update? is permitted for system admin" do
    assert SubmissionPolicy.new(@system_admin_user, @submission).update?
  end

  test "update? is permitted for feed group member (can moderate)" do
    # admin user is a member of feed_two_owners, which owns feed two
    assert SubmissionPolicy.new(@content_owner, @submission).update?
  end

  test "update? is denied for non-member of feed group" do
    refute SubmissionPolicy.new(@non_member, @submission).update?
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

  test "destroy? is permitted for system admin" do
    assert SubmissionPolicy.new(@system_admin_user, @submission).destroy?
  end

  test "destroy? is permitted for content owner" do
    assert SubmissionPolicy.new(@content_owner, @submission).destroy?
  end

  test "destroy? is denied for non-owner without feed group" do
    refute SubmissionPolicy.new(@other_user, @submission).destroy?
  end

  test "destroy? is denied for anonymous users" do
    refute SubmissionPolicy.new(nil, @submission).destroy?
  end
end

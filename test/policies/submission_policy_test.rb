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

  test "edit? is permitted for system admin only" do
    assert SubmissionPolicy.new(@system_admin_user, @submission).edit?
  end

  test "edit? is denied for content owner (no moderation yet)" do
    refute SubmissionPolicy.new(@content_owner, @submission).edit?
  end

  test "edit? is denied for other users" do
    refute SubmissionPolicy.new(@other_user, @submission).edit?
  end

  test "update? is permitted for system admin only" do
    assert SubmissionPolicy.new(@system_admin_user, @submission).update?
  end

  test "update? is denied for content owner (no moderation yet)" do
    refute SubmissionPolicy.new(@content_owner, @submission).update?
  end

  test "update? is denied for other users" do
    refute SubmissionPolicy.new(@other_user, @submission).update?
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

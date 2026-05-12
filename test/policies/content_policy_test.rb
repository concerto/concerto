require "test_helper"

class ContentPolicyTest < ActiveSupport::TestCase
  setup do
    @system_admin_user = users(:system_admin)
    @content_owner = users(:admin)  # Owner of the content
    @other_user = users(:regular)
    @non_member = users(:non_member)
    @content = rich_texts(:plain_richtext)  # Owned by admin user
  end

  test "scope returns only approved content for anonymous users" do
    resolved_scope = ContentPolicy::Scope.new(nil, Content.all).resolve
    assert_equal Content.approved.to_a.to_set, resolved_scope.to_a.to_set
  end

  test "scope returns approved content for users who own none of it" do
    # @other_user owns no content in fixtures, so the additional OR clause
    # contributes nothing — they still see exactly the approved set.
    assert_equal 0, Content.where(user_id: @other_user.id).count
    resolved_scope = ContentPolicy::Scope.new(@other_user, Content.all).resolve
    assert_equal Content.approved.to_a.to_set, resolved_scope.to_a.to_set
  end

  test "scope includes pending content owned by the signed-in user" do
    # non_member is not in feed_one_owners, so submissions stay pending.
    pending_content = RichText.create!(
      name: "My Pending Content", text: "Test", duration: 10, user: @non_member,
      config: { "render_as" => "plaintext" }
    )
    submission = Submission.create!(content: pending_content, feed: feeds(:one))
    assert submission.pending?, "Expected submission to be pending"

    assert_not_includes ContentPolicy::Scope.new(nil, Content.all).resolve, pending_content
    assert_includes ContentPolicy::Scope.new(@non_member, Content.all).resolve, pending_content
  end

  test "scope includes rejected content owned by the signed-in user" do
    rejected_content = RichText.create!(
      name: "My Rejected Content", text: "Test", duration: 10, user: @non_member,
      config: { "render_as" => "plaintext" }
    )
    Submission.create!(content: rejected_content, feed: feeds(:one))
      .moderate!(status: :rejected, moderator: @content_owner, reason: "Nope")

    assert_not_includes ContentPolicy::Scope.new(nil, Content.all).resolve, rejected_content
    assert_includes ContentPolicy::Scope.new(@non_member, Content.all).resolve, rejected_content
  end

  test "scope includes unsubmitted content owned by the signed-in user" do
    draft = RichText.create!(
      name: "My Draft", text: "Test", duration: 10, user: @non_member,
      config: { "render_as" => "plaintext" }
    )

    assert_not_includes ContentPolicy::Scope.new(nil, Content.all).resolve, draft
    assert_includes ContentPolicy::Scope.new(@non_member, Content.all).resolve, draft
  end

  test "scope does not include another user's unapproved content" do
    pending_content = RichText.create!(
      name: "Someone Else's Draft", text: "Test", duration: 10, user: @non_member,
      config: { "render_as" => "plaintext" }
    )

    assert_not_includes ContentPolicy::Scope.new(@other_user, Content.all).resolve, pending_content
  end

  test "scope excludes content with only pending submissions" do
    content = RichText.create!(
      name: "Pending Only", text: "Test", duration: 10, user: @non_member,
      config: { "render_as" => "plaintext" }
    )
    submission = Submission.create!(content: content, feed: feeds(:one))
    assert submission.pending?, "Expected submission to be pending for non-member"

    resolved_scope = ContentPolicy::Scope.new(nil, Content.all).resolve
    assert_not_includes resolved_scope, content
  end

  test "scope excludes content with only rejected submissions" do
    content = RichText.create!(
      name: "Rejected Only", text: "Test", duration: 10, user: @non_member,
      config: { "render_as" => "plaintext" }
    )
    submission = Submission.create!(content: content, feed: feeds(:one))
    submission.moderate!(status: :rejected, moderator: @content_owner, reason: "No")

    resolved_scope = ContentPolicy::Scope.new(nil, Content.all).resolve
    assert_not_includes resolved_scope, content
  end

  test "scope includes content with at least one approved submission" do
    content = RichText.create!(
      name: "Has Approved", text: "Test", duration: 10, user: @non_member,
      config: { "render_as" => "plaintext" }
    )
    Submission.create!(content: content, feed: feeds(:one)) # pending for non-member
    Submission.create!(content: content, feed: feeds(:two)).moderate!(status: :approved, moderator: @content_owner, reason: "OK")

    resolved_scope = ContentPolicy::Scope.new(nil, Content.all).resolve
    assert_includes resolved_scope, content
  end

  test "scope excludes content with no submissions" do
    content = RichText.create!(
      name: "No Submissions", text: "Test", duration: 10, user: @non_member,
      config: { "render_as" => "plaintext" }
    )

    resolved_scope = ContentPolicy::Scope.new(nil, Content.all).resolve
    assert_not_includes resolved_scope, content
  end

  test "index? is permitted for everyone" do
    assert ContentPolicy.new(nil, Content).index?
    assert ContentPolicy.new(@non_member, Content).index?
  end

  test "show? is permitted for everyone" do
    assert ContentPolicy.new(nil, @content).show?
    assert ContentPolicy.new(@non_member, @content).show?
  end

  test "new? is permitted for system admin" do
    assert ContentPolicy.new(@system_admin_user, Content.new).new?
  end

  test "new? is permitted for any signed-in user" do
    assert ContentPolicy.new(@other_user, Content.new).new?
    assert ContentPolicy.new(@content_owner, Content.new).new?
  end

  test "new? is denied for anonymous users" do
    refute ContentPolicy.new(nil, Content.new).new?
  end

  test "create? is permitted for system admin" do
    assert ContentPolicy.new(@system_admin_user, Content.new).create?
  end

  test "create? is permitted for any signed-in user" do
    assert ContentPolicy.new(@other_user, Content.new).create?
    assert ContentPolicy.new(@content_owner, Content.new).create?
  end

  test "create? is denied for anonymous users" do
    refute ContentPolicy.new(nil, Content.new).create?
  end

  test "edit? is permitted for system admin" do
    assert ContentPolicy.new(@system_admin_user, @content).edit?
  end

  test "edit? is permitted for content owner" do
    assert ContentPolicy.new(@content_owner, @content).edit?
  end

  test "edit? is denied for non-owner" do
    refute ContentPolicy.new(@other_user, @content).edit?
  end

  test "edit? is denied for anonymous users" do
    refute ContentPolicy.new(nil, @content).edit?
  end

  test "update? is permitted for system admin" do
    assert ContentPolicy.new(@system_admin_user, @content).update?
  end

  test "update? is permitted for content owner" do
    assert ContentPolicy.new(@content_owner, @content).update?
  end

  test "update? is denied for non-owner" do
    refute ContentPolicy.new(@other_user, @content).update?
  end

  test "update? is denied for anonymous users" do
    refute ContentPolicy.new(nil, @content).update?
  end

  test "destroy? is permitted for system admin" do
    assert ContentPolicy.new(@system_admin_user, @content).destroy?
  end

  test "destroy? is permitted for content owner" do
    assert ContentPolicy.new(@content_owner, @content).destroy?
  end

  test "destroy? is denied for non-owner" do
    refute ContentPolicy.new(@other_user, @content).destroy?
  end

  test "destroy? is denied for anonymous users" do
    refute ContentPolicy.new(nil, @content).destroy?
  end
end

require "test_helper"

class ContentPolicyTest < ActiveSupport::TestCase
  setup do
    @system_admin_user = users(:system_admin)
    @content_owner = users(:admin)  # Owner of the content
    @other_user = users(:regular)
    @non_member = users(:non_member)
    @content = rich_texts(:plain_richtext)  # Owned by admin user
  end

  test "scope returns all content for everyone" do
    resolved_scope = ContentPolicy::Scope.new(nil, Content.all).resolve
    assert_equal Content.all.to_a, resolved_scope.to_a

    resolved_scope = ContentPolicy::Scope.new(@other_user, Content.all).resolve
    assert_equal Content.all.to_a, resolved_scope.to_a
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

require "test_helper"

class MembershipPolicyTest < ActiveSupport::TestCase
  setup do
    @system_admin_user = users(:system_admin)
    @group_admin_user = users(:admin)
    @group_regular_user = users(:regular)
    @non_group_user = users(:non_member)
    @group = groups(:content_creators)
    @membership = memberships(:regular_content_creator)
  end

  test "scope returns all memberships for signed-in users" do
    resolved_scope = MembershipPolicy::Scope.new(@group_regular_user, Membership.all).resolve
    assert_equal Membership.all.to_a, resolved_scope.to_a
  end

  test "scope returns no memberships for anonymous users" do
    resolved_scope = MembershipPolicy::Scope.new(nil, Membership.all).resolve
    assert_equal [], resolved_scope.to_a
  end

  test "index? is permitted for signed-in users" do
    assert MembershipPolicy.new(@group_regular_user, Membership).index?
  end

  test "index? is denied for anonymous users" do
    refute MembershipPolicy.new(nil, Membership).index?
  end

  test "show? is permitted for signed-in users" do
    assert MembershipPolicy.new(@group_regular_user, @membership).show?
  end

  test "show? is denied for anonymous users" do
    refute MembershipPolicy.new(nil, @membership).show?
  end

  test "new? is permitted for system admin" do
    new_membership = @group.memberships.build
    assert MembershipPolicy.new(@system_admin_user, new_membership).new?
  end

  test "new? is permitted for group admin" do
    new_membership = @group.memberships.build
    assert MembershipPolicy.new(@group_admin_user, new_membership).new?
  end

  test "new? is denied for regular group member" do
    new_membership = @group.memberships.build
    refute MembershipPolicy.new(@group_regular_user, new_membership).new?
  end

  test "new? is denied for non-group member" do
    new_membership = @group.memberships.build
    refute MembershipPolicy.new(@non_group_user, new_membership).new?
  end

  test "create? is permitted for system admin" do
    new_membership = @group.memberships.build
    assert MembershipPolicy.new(@system_admin_user, new_membership).create?
  end

  test "create? is permitted for group admin" do
    new_membership = @group.memberships.build
    assert MembershipPolicy.new(@group_admin_user, new_membership).create?
  end

  test "create? is denied for regular group member" do
    new_membership = @group.memberships.build
    refute MembershipPolicy.new(@group_regular_user, new_membership).create?
  end

  test "create? is denied for non-group member" do
    new_membership = @group.memberships.build
    refute MembershipPolicy.new(@non_group_user, new_membership).create?
  end

  test "edit? is permitted for system admin" do
    assert MembershipPolicy.new(@system_admin_user, @membership).edit?
  end

  test "edit? is permitted for group admin" do
    assert MembershipPolicy.new(@group_admin_user, @membership).edit?
  end

  test "edit? is denied for regular group member" do
    refute MembershipPolicy.new(@group_regular_user, @membership).edit?
  end

  test "edit? is denied for non-group member" do
    refute MembershipPolicy.new(@non_group_user, @membership).edit?
  end

  test "update? is permitted for system admin" do
    assert MembershipPolicy.new(@system_admin_user, @membership).update?
  end

  test "update? is permitted for group admin" do
    assert MembershipPolicy.new(@group_admin_user, @membership).update?
  end

  test "update? is denied for regular group member" do
    refute MembershipPolicy.new(@group_regular_user, @membership).update?
  end

  test "update? is denied for non-group member" do
    refute MembershipPolicy.new(@non_group_user, @membership).update?
  end

  test "destroy? is permitted for system admin" do
    assert MembershipPolicy.new(@system_admin_user, @membership).destroy?
  end

  test "destroy? is permitted for group admin" do
    assert MembershipPolicy.new(@group_admin_user, @membership).destroy?
  end

  test "destroy? is permitted for user removing themselves" do
    assert MembershipPolicy.new(@group_regular_user, @membership).destroy?
  end

  test "destroy? is denied for regular user removing someone else" do
    other_membership = memberships(:admin_content_creator)
    refute MembershipPolicy.new(@group_regular_user, other_membership).destroy?
  end

  test "destroy? is denied for non-group member" do
    refute MembershipPolicy.new(@non_group_user, @membership).destroy?
  end

  test "permitted_attributes includes role for system admin" do
    policy = MembershipPolicy.new(@system_admin_user, @membership)
    assert_includes policy.permitted_attributes, :role
  end

  test "permitted_attributes includes role for group admin" do
    policy = MembershipPolicy.new(@group_admin_user, @membership)
    assert_includes policy.permitted_attributes, :role
  end

  test "permitted_attributes excludes role for regular group member" do
    policy = MembershipPolicy.new(@group_regular_user, @membership)
    refute_includes policy.permitted_attributes, :role
  end

  test "permitted_attributes excludes role for non-group member" do
    policy = MembershipPolicy.new(@non_group_user, @membership)
    refute_includes policy.permitted_attributes, :role
  end

  test "can_edit_role? is true for system admin" do
    policy = MembershipPolicy.new(@system_admin_user, @membership)
    assert policy.can_edit_role?
  end

  test "can_edit_role? is true for group admin" do
    policy = MembershipPolicy.new(@group_admin_user, @membership)
    assert policy.can_edit_role?
  end

  test "can_edit_role? is false for regular group member" do
    policy = MembershipPolicy.new(@group_regular_user, @membership)
    refute policy.can_edit_role?
  end
end

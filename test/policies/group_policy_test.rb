require "test_helper"

class GroupPolicyTest < ActiveSupport::TestCase
  setup do
    @system_admin_user = users(:system_admin)
    @group_admin_user = users(:admin)
    @group_regular_user = users(:regular)
    @non_group_user = users(:non_member)
    @group = groups(:content_creators)
  end

  test "scope returns all groups for everyone" do
    resolved_scope = GroupPolicy::Scope.new(nil, Group.all).resolve
    assert_equal Group.all.to_a, resolved_scope.to_a

    resolved_scope = GroupPolicy::Scope.new(@group_regular_user, Group.all).resolve
    assert_equal Group.all.to_a, resolved_scope.to_a
  end

  test "index? is permitted for everyone" do
    assert GroupPolicy.new(nil, Group).index?
    assert GroupPolicy.new(@non_group_user, Group).index?
  end

  test "show? is permitted for everyone" do
    assert GroupPolicy.new(nil, @group).show?
    assert GroupPolicy.new(@non_group_user, @group).show?
  end

  test "new? is permitted for system admin only" do
    assert GroupPolicy.new(@system_admin_user, Group.new).new?
  end

  test "new? is denied for non-system admin" do
    refute GroupPolicy.new(@group_admin_user, Group.new).new?
    refute GroupPolicy.new(@non_group_user, Group.new).new?
  end

  test "create? is permitted for system admin only" do
    assert GroupPolicy.new(@system_admin_user, Group.new).create?
  end

  test "create? is denied for non-system admin" do
    refute GroupPolicy.new(@group_admin_user, Group.new).create?
    refute GroupPolicy.new(@non_group_user, Group.new).create?
  end

  test "edit? is permitted for system admin" do
    assert GroupPolicy.new(@system_admin_user, @group).edit?
  end

  test "edit? is permitted for group admin" do
    assert GroupPolicy.new(@group_admin_user, @group).edit?
  end

  test "edit? is denied for regular group member" do
    refute GroupPolicy.new(@group_regular_user, @group).edit?
  end

  test "edit? is denied for non-group member" do
    refute GroupPolicy.new(@non_group_user, @group).edit?
  end

  test "update? is permitted for system admin" do
    assert GroupPolicy.new(@system_admin_user, @group).update?
  end

  test "update? is permitted for group admin" do
    assert GroupPolicy.new(@group_admin_user, @group).update?
  end

  test "update? is denied for regular group member" do
    refute GroupPolicy.new(@group_regular_user, @group).update?
  end

  test "update? is denied for non-group member" do
    refute GroupPolicy.new(@non_group_user, @group).update?
  end

  test "destroy? is permitted for system admin only" do
    assert GroupPolicy.new(@system_admin_user, @group).destroy?
  end

  test "destroy? is denied for non-system admin" do
    refute GroupPolicy.new(@group_admin_user, @group).destroy?
    refute GroupPolicy.new(@non_group_user, @group).destroy?
  end
end

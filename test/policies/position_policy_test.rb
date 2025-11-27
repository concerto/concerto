require "test_helper"

class PositionPolicyTest < ActiveSupport::TestCase
  setup do
    @system_admin_user = users(:system_admin)
    @group_admin_user = users(:admin)  # Admin of screen_one_owners group
    @group_regular_user = users(:regular)
    @non_group_user = users(:non_member)
    @position = positions(:one)
  end

  test "scope returns all positions for everyone" do
    resolved_scope = PositionPolicy::Scope.new(nil, Position.all).resolve
    assert_equal Position.all.to_a, resolved_scope.to_a

    resolved_scope = PositionPolicy::Scope.new(@group_regular_user, Position.all).resolve
    assert_equal Position.all.to_a, resolved_scope.to_a
  end

  test "index? is permitted for everyone" do
    assert PositionPolicy.new(nil, Position).index?
    assert PositionPolicy.new(@non_group_user, Position).index?
  end

  test "show? is permitted for everyone" do
    assert PositionPolicy.new(nil, @position).show?
    assert PositionPolicy.new(@non_group_user, @position).show?
  end

  test "new? is permitted for system admin" do
    assert PositionPolicy.new(@system_admin_user, Position.new).new?
  end

  test "new? is permitted for user who is an admin of a group owning a screen" do
    assert PositionPolicy.new(@group_admin_user, Position.new).new?
  end

  test "new? is denied for user who is not an admin of a group owning a screen" do
    refute PositionPolicy.new(@group_regular_user, Position.new).new?
    refute PositionPolicy.new(@non_group_user, Position.new).new?
  end

  test "create? is permitted for system admin" do
    assert PositionPolicy.new(@system_admin_user, Position.new).create?
  end

  test "create? is permitted for user who is an admin of a group owning a screen" do
    assert PositionPolicy.new(@group_admin_user, Position.new).create?
  end

  test "create? is denied for user who is not an admin of a group owning a screen" do
    refute PositionPolicy.new(@group_regular_user, Position.new).create?
    refute PositionPolicy.new(@non_group_user, Position.new).create?
  end

  test "edit? is permitted for system admin only" do
    assert PositionPolicy.new(@system_admin_user, @position).edit?
  end

  test "edit? is denied for non-system admin" do
    refute PositionPolicy.new(@group_admin_user, @position).edit?
    refute PositionPolicy.new(@non_group_user, @position).edit?
  end

  test "update? is permitted for system admin only" do
    assert PositionPolicy.new(@system_admin_user, @position).update?
  end

  test "update? is denied for non-system admin" do
    refute PositionPolicy.new(@group_admin_user, @position).update?
    refute PositionPolicy.new(@non_group_user, @position).update?
  end

  test "destroy? is permitted for system admin only" do
    assert PositionPolicy.new(@system_admin_user, @position).destroy?
  end

  test "destroy? is denied for non-system admin" do
    refute PositionPolicy.new(@group_admin_user, @position).destroy?
    refute PositionPolicy.new(@non_group_user, @position).destroy?
  end
end

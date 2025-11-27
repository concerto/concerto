require "test_helper"

class FieldPolicyTest < ActiveSupport::TestCase
  setup do
    @system_admin_user = users(:system_admin)
    @group_admin_user = users(:admin)
    @group_regular_user = users(:regular)
    @non_group_user = users(:non_member)
    @field = fields(:main)
  end

  test "scope returns all fields for everyone" do
    resolved_scope = FieldPolicy::Scope.new(nil, Field.all).resolve
    assert_equal Field.all.to_a, resolved_scope.to_a

    resolved_scope = FieldPolicy::Scope.new(@group_regular_user, Field.all).resolve
    assert_equal Field.all.to_a, resolved_scope.to_a
  end

  test "index? is permitted for everyone" do
    assert FieldPolicy.new(nil, Field).index?
    assert FieldPolicy.new(@non_group_user, Field).index?
  end

  test "show? is permitted for everyone" do
    assert FieldPolicy.new(nil, @field).show?
    assert FieldPolicy.new(@non_group_user, @field).show?
  end

  test "new? is permitted for system admin only" do
    assert FieldPolicy.new(@system_admin_user, Field.new).new?
  end

  test "new? is denied for non-system admin" do
    refute FieldPolicy.new(@group_admin_user, Field.new).new?
    refute FieldPolicy.new(@non_group_user, Field.new).new?
  end

  test "create? is permitted for system admin only" do
    assert FieldPolicy.new(@system_admin_user, Field.new).create?
  end

  test "create? is denied for non-system admin" do
    refute FieldPolicy.new(@group_admin_user, Field.new).create?
    refute FieldPolicy.new(@non_group_user, Field.new).create?
  end

  test "edit? is permitted for system admin only" do
    assert FieldPolicy.new(@system_admin_user, @field).edit?
  end

  test "edit? is denied for non-system admin" do
    refute FieldPolicy.new(@group_admin_user, @field).edit?
    refute FieldPolicy.new(@non_group_user, @field).edit?
  end

  test "update? is permitted for system admin only" do
    assert FieldPolicy.new(@system_admin_user, @field).update?
  end

  test "update? is denied for non-system admin" do
    refute FieldPolicy.new(@group_admin_user, @field).update?
    refute FieldPolicy.new(@non_group_user, @field).update?
  end

  test "destroy? is permitted for system admin only" do
    assert FieldPolicy.new(@system_admin_user, @field).destroy?
  end

  test "destroy? is denied for non-system admin" do
    refute FieldPolicy.new(@group_admin_user, @field).destroy?
    refute FieldPolicy.new(@non_group_user, @field).destroy?
  end
end

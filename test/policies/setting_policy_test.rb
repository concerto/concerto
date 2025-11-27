require "test_helper"

class SettingPolicyTest < ActiveSupport::TestCase
  setup do
    @system_admin_user = users(:system_admin)
    @group_admin_user = users(:admin)
    @regular_user = users(:regular)
    @setting = settings(:site_name)
  end

  test "scope returns all settings for system admin" do
    resolved_scope = SettingPolicy::Scope.new(@system_admin_user, Setting.all).resolve
    assert_equal Setting.all.to_a, resolved_scope.to_a
  end

  test "scope returns no settings for non-system admin" do
    resolved_scope = SettingPolicy::Scope.new(@group_admin_user, Setting.all).resolve
    assert_equal [], resolved_scope.to_a

    resolved_scope = SettingPolicy::Scope.new(@regular_user, Setting.all).resolve
    assert_equal [], resolved_scope.to_a
  end

  test "scope returns no settings for anonymous users" do
    resolved_scope = SettingPolicy::Scope.new(nil, Setting.all).resolve
    assert_equal [], resolved_scope.to_a
  end

  test "index? is permitted for system admin only" do
    assert SettingPolicy.new(@system_admin_user, Setting).index?
  end

  test "index? is denied for non-system admin" do
    refute SettingPolicy.new(@group_admin_user, Setting).index?
    refute SettingPolicy.new(@regular_user, Setting).index?
    refute SettingPolicy.new(nil, Setting).index?
  end

  test "show? is permitted for system admin only" do
    assert SettingPolicy.new(@system_admin_user, @setting).show?
  end

  test "show? is denied for non-system admin" do
    refute SettingPolicy.new(@group_admin_user, @setting).show?
    refute SettingPolicy.new(@regular_user, @setting).show?
    refute SettingPolicy.new(nil, @setting).show?
  end

  test "new? is permitted for system admin only" do
    assert SettingPolicy.new(@system_admin_user, Setting.new).new?
  end

  test "new? is denied for non-system admin" do
    refute SettingPolicy.new(@group_admin_user, Setting.new).new?
    refute SettingPolicy.new(@regular_user, Setting.new).new?
    refute SettingPolicy.new(nil, Setting.new).new?
  end

  test "create? is permitted for system admin only" do
    assert SettingPolicy.new(@system_admin_user, Setting.new).create?
  end

  test "create? is denied for non-system admin" do
    refute SettingPolicy.new(@group_admin_user, Setting.new).create?
    refute SettingPolicy.new(@regular_user, Setting.new).create?
    refute SettingPolicy.new(nil, Setting.new).create?
  end

  test "edit? is permitted for system admin only" do
    assert SettingPolicy.new(@system_admin_user, @setting).edit?
  end

  test "edit? is denied for non-system admin" do
    refute SettingPolicy.new(@group_admin_user, @setting).edit?
    refute SettingPolicy.new(@regular_user, @setting).edit?
    refute SettingPolicy.new(nil, @setting).edit?
  end

  test "update? is permitted for system admin only" do
    assert SettingPolicy.new(@system_admin_user, @setting).update?
  end

  test "update? is denied for non-system admin" do
    refute SettingPolicy.new(@group_admin_user, @setting).update?
    refute SettingPolicy.new(@regular_user, @setting).update?
    refute SettingPolicy.new(nil, @setting).update?
  end

  test "destroy? is permitted for system admin only" do
    assert SettingPolicy.new(@system_admin_user, @setting).destroy?
  end

  test "destroy? is denied for non-system admin" do
    refute SettingPolicy.new(@group_admin_user, @setting).destroy?
    refute SettingPolicy.new(@regular_user, @setting).destroy?
    refute SettingPolicy.new(nil, @setting).destroy?
  end
end

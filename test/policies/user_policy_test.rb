require "test_helper"

class UserPolicyTest < ActiveSupport::TestCase
  setup do
    @system_admin_user = users(:system_admin)
    @regular_user = users(:regular)
    @other_user = users(:admin)
  end

  test "scope returns all users for signed-in users" do
    resolved_scope = UserPolicy::Scope.new(@regular_user, User.all).resolve
    assert_equal User.all.to_a, resolved_scope.to_a
  end

  test "scope returns no users for anonymous users" do
    resolved_scope = UserPolicy::Scope.new(nil, User.all).resolve
    assert_equal [], resolved_scope.to_a
  end

  test "index? is permitted for signed-in users" do
    assert UserPolicy.new(@regular_user, User).index?
  end

  test "index? is denied for anonymous users" do
    refute UserPolicy.new(nil, User).index?
  end

  test "show? is permitted for signed-in users" do
    assert UserPolicy.new(@other_user, @regular_user).show?
  end

  test "show? is denied for anonymous users" do
    refute UserPolicy.new(nil, @regular_user).show?
  end

  test "new? is permitted for everyone (Devise handles registration)" do
    assert UserPolicy.new(nil, User.new).new?
    assert UserPolicy.new(@regular_user, User.new).new?
  end

  test "create? is permitted for everyone (Devise handles registration)" do
    assert UserPolicy.new(nil, User.new).create?
    assert UserPolicy.new(@regular_user, User.new).create?
  end

  test "edit? is permitted for system admin on any user" do
    assert UserPolicy.new(@system_admin_user, @regular_user).edit?
  end

  test "edit? is permitted for user editing themselves" do
    assert UserPolicy.new(@regular_user, @regular_user).edit?
  end

  test "edit? is denied for user editing someone else" do
    refute UserPolicy.new(@regular_user, @other_user).edit?
  end

  test "update? is permitted for system admin on any user" do
    assert UserPolicy.new(@system_admin_user, @regular_user).update?
  end

  test "update? is permitted for user updating themselves" do
    assert UserPolicy.new(@regular_user, @regular_user).update?
  end

  test "update? is denied for user updating someone else" do
    refute UserPolicy.new(@regular_user, @other_user).update?
  end

  test "destroy? is permitted for system admin on any user" do
    assert UserPolicy.new(@system_admin_user, @regular_user).destroy?
  end

  test "destroy? is permitted for user destroying themselves" do
    assert UserPolicy.new(@regular_user, @regular_user).destroy?
  end

  test "destroy? is denied for user destroying someone else" do
    refute UserPolicy.new(@regular_user, @other_user).destroy?
  end
end

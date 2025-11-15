require "test_helper"

class SubscriptionPolicyTest < ActiveSupport::TestCase
  setup do
    @system_admin_user = users(:system_admin)
    @group_admin_user = users(:admin)
    @group_regular_user = users(:regular)
    @non_group_user = users(:non_member)
    @subscription = subscriptions(:one) # belongs to screen :one
  end

  test "index? is permitted for all users" do
    assert SubscriptionPolicy.new(nil, @subscription).index?
    assert SubscriptionPolicy.new(@non_group_user, @subscription).index?
    assert SubscriptionPolicy.new(@group_regular_user, @subscription).index?
  end

  test "show? is permitted for all users" do
    assert SubscriptionPolicy.new(nil, @subscription).show?
    assert SubscriptionPolicy.new(@non_group_user, @subscription).show?
    assert SubscriptionPolicy.new(@group_regular_user, @subscription).show?
  end

  test "scope resolves to all subscriptions" do
    resolved_scope = SubscriptionPolicy::Scope.new(nil, Subscription.all).resolve
    assert_equal Subscription.all.to_a, resolved_scope.to_a
  end

  # --- Create, Edit, Destroy Tests --- #

  test "new? is permitted for system admin" do
    assert SubscriptionPolicy.new(@system_admin_user, @subscription).new?
  end

  test "new? is permitted for a group admin" do
    assert SubscriptionPolicy.new(@group_admin_user, @subscription).new?
  end

  test "new? is permitted for a regular group member" do
    assert SubscriptionPolicy.new(@group_regular_user, @subscription).new?
  end

  test "new? is denied for a non-group member" do
    refute SubscriptionPolicy.new(@non_group_user, @subscription).new?
  end

  test "new? is denied for non-logged-in user" do
    refute SubscriptionPolicy.new(nil, @subscription).new?
  end

  test "create? is permitted for system admin" do
    assert SubscriptionPolicy.new(@system_admin_user, @subscription).create?
  end

  test "create? is permitted for a group admin" do
    assert SubscriptionPolicy.new(@group_admin_user, @subscription).create?
  end

  test "create? is permitted for a regular group member" do
    assert SubscriptionPolicy.new(@group_regular_user, @subscription).create?
  end

  test "create? is denied for a non-group member" do
    refute SubscriptionPolicy.new(@non_group_user, @subscription).create?
  end

  test "create? is denied for non-logged-in user" do
    refute SubscriptionPolicy.new(nil, @subscription).create?
  end

  test "update? is permitted for a group admin" do
    assert SubscriptionPolicy.new(@group_admin_user, @subscription).update?
  end

  test "update? is permitted for a regular group member" do
    assert SubscriptionPolicy.new(@group_regular_user, @subscription).update?
  end

  test "update? is denied for a non-group member" do
    refute SubscriptionPolicy.new(@non_group_user, @subscription).update?
  end

  test "update? is denied for non-logged-in user" do
    refute SubscriptionPolicy.new(nil, @subscription).update?
  end

  test "destroy? is permitted for system admin" do
    assert SubscriptionPolicy.new(@system_admin_user, @subscription).destroy?
  end

  test "destroy? is permitted for a group admin" do
    assert SubscriptionPolicy.new(@group_admin_user, @subscription).destroy?
  end

  test "destroy? is permitted for a regular group member" do
    assert SubscriptionPolicy.new(@group_regular_user, @subscription).destroy?
  end

  test "destroy? is denied for a non-group member" do
    refute SubscriptionPolicy.new(@non_group_user, @subscription).destroy?
  end

  test "destroy? is denied for non-logged-in user" do
    refute SubscriptionPolicy.new(nil, @subscription).destroy?
  end
end

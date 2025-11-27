require "test_helper"

class FeedPolicyTest < ActiveSupport::TestCase
  setup do
    @system_admin_user = users(:system_admin)
    @group_admin_user = users(:admin)
    @group_regular_user = users(:regular)
    @non_group_user = users(:non_member)
    @feed = feeds(:one)
  end

  test "scope returns all feeds for everyone" do
    resolved_scope = FeedPolicy::Scope.new(nil, Feed.all).resolve
    assert_equal Feed.all.to_a, resolved_scope.to_a

    resolved_scope = FeedPolicy::Scope.new(@group_regular_user, Feed.all).resolve
    assert_equal Feed.all.to_a, resolved_scope.to_a
  end

  test "index? is permitted for everyone" do
    assert FeedPolicy.new(nil, Feed).index?
    assert FeedPolicy.new(@non_group_user, Feed).index?
  end

  test "show? is permitted for everyone" do
    assert FeedPolicy.new(nil, @feed).show?
    assert FeedPolicy.new(@non_group_user, @feed).show?
  end

  test "new? is permitted for system admin" do
    assert FeedPolicy.new(@system_admin_user, Feed.new).new?
  end

  test "new? is permitted for user who is an admin of any group" do
    assert FeedPolicy.new(@group_admin_user, Feed.new).new?
  end

  test "new? is denied for user who is not an admin of any group" do
    refute FeedPolicy.new(@group_regular_user, Feed.new).new?
  end

  test "create? is permitted for system admin" do
    assert FeedPolicy.new(@system_admin_user, @feed).create?
  end

  test "create? is permitted for user who is an admin of any group" do
    assert FeedPolicy.new(@group_admin_user, Feed.new).create?
  end

  test "create? is denied for user who is not an admin of any group" do
    refute FeedPolicy.new(@group_regular_user, Feed.new).create?
  end

  # The following require system admin until Feed has group association
  test "edit? is permitted for system admin" do
    assert FeedPolicy.new(@system_admin_user, @feed).edit?
  end

  test "update? is permitted for system admin" do
    assert FeedPolicy.new(@system_admin_user, @feed).update?
  end

  test "destroy? is permitted for system admin" do
    assert FeedPolicy.new(@system_admin_user, @feed).destroy?
  end

  test "edit? is denied for non-system admin" do
    refute FeedPolicy.new(@group_admin_user, @feed).edit?
  end

  test "update? is denied for non-system admin" do
    refute FeedPolicy.new(@group_admin_user, @feed).update?
  end

  test "destroy? is denied for non-system admin" do
    refute FeedPolicy.new(@group_admin_user, @feed).destroy?
  end

  test "permitted_attributes includes group_id for system admin" do
    policy = FeedPolicy.new(@system_admin_user, @feed)
    assert_includes policy.permitted_attributes, :group_id
  end

  test "permitted_attributes includes name, description, type, config for all" do
    policy = FeedPolicy.new(@system_admin_user, @feed)
    assert_includes policy.permitted_attributes, :name
    assert_includes policy.permitted_attributes, :description
    assert_includes policy.permitted_attributes, :type
    assert_includes policy.permitted_attributes, :config
  end
end

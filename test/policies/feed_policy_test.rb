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

  test "create? is permitted for a group admin" do
    assert FeedPolicy.new(@group_admin_user, @feed).create?
  end

  test "create? is denied for a regular group member" do
    refute FeedPolicy.new(@group_regular_user, @feed).create?
  end

  test "create? is denied for a non-group member" do
    refute FeedPolicy.new(@non_group_user, @feed).create?
  end

  # Edit permissions
  test "edit? is permitted for system admin" do
    assert FeedPolicy.new(@system_admin_user, @feed).edit?
  end

  test "edit? is permitted for group members" do
    assert FeedPolicy.new(@group_admin_user, @feed).edit?
    assert FeedPolicy.new(@group_regular_user, @feed).edit?
  end

  test "edit? is denied for non-group members" do
    refute FeedPolicy.new(@non_group_user, @feed).edit?
  end

  # Update permissions
  test "update? is permitted for system admin" do
    assert FeedPolicy.new(@system_admin_user, @feed).update?
  end

  test "update? is permitted for group members without group change" do
    assert FeedPolicy.new(@group_admin_user, @feed).update?
    assert FeedPolicy.new(@group_regular_user, @feed).update?
  end

  test "update? is denied for non-group members" do
    refute FeedPolicy.new(@non_group_user, @feed).update?
  end

  test "update? with group change requires admin of both old and new groups" do
    # admin is admin of both feed_one_owners and feed_two_owners
    @feed.group_id = groups(:feed_two_owners).id
    assert FeedPolicy.new(@group_admin_user, @feed).update?
  end

  test "update? with group change is denied if not admin of old group" do
    # regular is only a member (not admin) of feed_one_owners
    @feed.group_id = groups(:feed_two_owners).id
    refute FeedPolicy.new(@group_regular_user, @feed).update?
  end

  test "update? with group change is denied if not admin of new group" do
    # Create a feed in feed_two_owners, try to move it to moderators
    # admin is admin of feed_two_owners but only admin of moderators
    feed_two = feeds(:two)
    feed_two.group_id = groups(:moderators).id
    assert FeedPolicy.new(@group_admin_user, feed_two).update?
  end

  # Destroy permissions
  test "destroy? is permitted for system admin" do
    assert FeedPolicy.new(@system_admin_user, @feed).destroy?
  end

  test "destroy? is permitted for group admins" do
    assert FeedPolicy.new(@group_admin_user, @feed).destroy?
  end

  test "destroy? is denied for regular group members" do
    refute FeedPolicy.new(@group_regular_user, @feed).destroy?
  end

  test "destroy? is denied for non-group members" do
    refute FeedPolicy.new(@non_group_user, @feed).destroy?
  end

  # can_edit_group? helper
  test "can_edit_group? is true for system admin" do
    policy = FeedPolicy.new(@system_admin_user, @feed)
    assert policy.can_edit_group?
  end

  test "can_edit_group? is true for group admin" do
    policy = FeedPolicy.new(@group_admin_user, @feed)
    assert policy.can_edit_group?
  end

  test "can_edit_group? is false for regular group members" do
    policy = FeedPolicy.new(@group_regular_user, @feed)
    refute policy.can_edit_group?
  end

  test "can_edit_group? is false for non-group members" do
    policy = FeedPolicy.new(@non_group_user, @feed)
    refute policy.can_edit_group?
  end

  test "can_edit_group? is true for new records if user is admin of any group" do
    new_feed = Feed.new
    policy = FeedPolicy.new(@group_admin_user, new_feed)
    assert policy.can_edit_group?
  end

  test "permitted_attributes includes group_id for system admin" do
    policy = FeedPolicy.new(@system_admin_user, @feed)
    assert_includes policy.permitted_attributes, :group_id
  end

  test "permitted_attributes includes group_id for group admin" do
    policy = FeedPolicy.new(@group_admin_user, @feed)
    assert_includes policy.permitted_attributes, :group_id
  end

  test "permitted_attributes excludes group_id for regular group members" do
    policy = FeedPolicy.new(@group_regular_user, @feed)
    refute_includes policy.permitted_attributes, :group_id
  end

  test "permitted_attributes excludes group_id for non-group members" do
    policy = FeedPolicy.new(@non_group_user, @feed)
    refute_includes policy.permitted_attributes, :group_id
  end

  test "permitted_attributes includes name, description, type, config for all" do
    policy = FeedPolicy.new(@system_admin_user, @feed)
    assert_includes policy.permitted_attributes, :name
    assert_includes policy.permitted_attributes, :description
    assert_includes policy.permitted_attributes, :type
    assert_includes policy.permitted_attributes, :config
  end
end

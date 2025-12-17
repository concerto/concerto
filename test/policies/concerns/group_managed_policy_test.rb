require "test_helper"

# Minimal test policy to verify the GroupManagedPolicy concern works correctly.
# Uses the Screen model/table for testing since it's a real group-managed entity.
class TestGroupManagedPolicy < ApplicationPolicy
  include GroupManagedPolicy

  def entity_specific_attributes
    [ :name ]
  end
end

class GroupManagedPolicyTest < ActiveSupport::TestCase
  setup do
    @system_admin_user = users(:system_admin)
    @group_admin_user = users(:admin)
    @group_regular_user = users(:regular)
    @non_group_user = users(:non_member)
    @screen = screens(:one)
  end

  # Tests for can_create_new?

  test "can_create_new? is true for admin of any group" do
    policy = TestGroupManagedPolicy.new(@group_admin_user, Screen.new)
    assert policy.can_create_new?, "Group admin should be able to create new entities"
  end

  test "can_create_new? is false for user with no admin groups" do
    policy = TestGroupManagedPolicy.new(@group_regular_user, Screen.new)
    refute policy.can_create_new?, "Regular member should not be able to create new entities"
  end

  test "can_create_new? is false for user not in any groups" do
    policy = TestGroupManagedPolicy.new(@non_group_user, Screen.new)
    refute policy.can_create_new?, "User not in any groups should not be able to create new entities"
  end

  test "can_create_new? is false for nil user" do
    policy = TestGroupManagedPolicy.new(nil, Screen.new)
    refute policy.can_create_new?, "Nil user should not be able to create new entities"
  end

  # Tests for can_create?

  test "can_create? is true for admin of entity's group" do
    policy = TestGroupManagedPolicy.new(@group_admin_user, @screen)
    assert policy.can_create?, "Group admin should be able to create entity in their group"
  end

  test "can_create? is false for regular member" do
    policy = TestGroupManagedPolicy.new(@group_regular_user, @screen)
    refute policy.can_create?, "Regular member should not be able to create entity"
  end

  test "can_create? is false for non-member" do
    policy = TestGroupManagedPolicy.new(@non_group_user, @screen)
    refute policy.can_create?, "Non-member should not be able to create entity"
  end

  test "can_create? falls back to can_create_new? for entity without group" do
    screen_without_group = Screen.new(name: "Test", template: templates(:one))
    screen_without_group.group = nil

    policy = TestGroupManagedPolicy.new(@group_admin_user, screen_without_group)
    assert policy.can_create?, "Should fall back to can_create_new? when group is nil"
  end

  # Tests for can_edit?

  test "can_edit? is true for group member" do
    policy = TestGroupManagedPolicy.new(@group_regular_user, @screen)
    assert policy.can_edit?, "Group member should be able to edit entity"
  end

  test "can_edit? is true for group admin" do
    policy = TestGroupManagedPolicy.new(@group_admin_user, @screen)
    assert policy.can_edit?, "Group admin should be able to edit entity"
  end

  test "can_edit? is false for non-member" do
    policy = TestGroupManagedPolicy.new(@non_group_user, @screen)
    refute policy.can_edit?, "Non-member should not be able to edit entity"
  end

  test "can_edit? is false for nil user" do
    policy = TestGroupManagedPolicy.new(nil, @screen)
    refute policy.can_edit?, "Nil user should not be able to edit entity"
  end

  # Tests for can_update?

  test "can_update? is true for group member when not changing group" do
    policy = TestGroupManagedPolicy.new(@group_regular_user, @screen)
    assert policy.can_update?, "Group member should be able to update entity"
  end

  test "can_update? validates group change requires admin of both groups" do
    # Change group from screen_one_owners to feed_one_owners (admin is admin of both)
    @screen.group_id = groups(:feed_one_owners).id
    policy = TestGroupManagedPolicy.new(@group_admin_user, @screen)
    assert policy.can_update?, "Admin of both groups should be able to change group"
  end

  test "can_update? denies group change if not admin of old group" do
    # Regular user is member (not admin) of screen_one_owners
    # Try to change to a group they're not admin of either
    @screen.group_id = groups(:screen_two_owners).id

    policy = TestGroupManagedPolicy.new(@group_regular_user, @screen)
    refute policy.can_update?, "User must be admin of old group to change it"
  end

  test "can_update? denies group change if not admin of new group" do
    # Admin user is admin of screen_one_owners but only member of screen_two_owners
    @screen.group_id = groups(:screen_two_owners).id
    policy = TestGroupManagedPolicy.new(@group_admin_user, @screen)
    refute policy.can_update?, "User must be admin of new group to change to it"
  end

  test "can_update? allows group change when user is admin of both old and new groups" do
    # Create screen, save it, then change the group
    screen = Screen.create!(name: "Test", template: templates(:one), group: groups(:screen_one_owners))
    screen.group_id = groups(:feed_one_owners).id

    policy = TestGroupManagedPolicy.new(@group_admin_user, screen)
    # This should work because admin is admin of both groups
    assert policy.can_update?, "Should allow group change if admin of both groups"
  end

  test "can_update? is false for non-member" do
    policy = TestGroupManagedPolicy.new(@non_group_user, @screen)
    refute policy.can_update?, "Non-member should not be able to update entity"
  end

  # Tests for can_destroy?

  test "can_destroy? is true for group admin" do
    policy = TestGroupManagedPolicy.new(@group_admin_user, @screen)
    assert policy.can_destroy?, "Group admin should be able to destroy entity"
  end

  test "can_destroy? is false for regular member" do
    policy = TestGroupManagedPolicy.new(@group_regular_user, @screen)
    refute policy.can_destroy?, "Regular member should not be able to destroy entity"
  end

  test "can_destroy? is false for non-member" do
    policy = TestGroupManagedPolicy.new(@non_group_user, @screen)
    refute policy.can_destroy?, "Non-member should not be able to destroy entity"
  end

  test "can_destroy? is false for nil user" do
    policy = TestGroupManagedPolicy.new(nil, @screen)
    refute policy.can_destroy?, "Nil user should not be able to destroy entity"
  end

  # Tests for permitted_attributes

  test "permitted_attributes includes group_id for group admin" do
    policy = TestGroupManagedPolicy.new(@group_admin_user, @screen)
    attributes = policy.permitted_attributes

    assert_includes attributes, :group_id, "Admin should be able to edit group_id"
    assert_includes attributes, :name, "Should include entity-specific attributes"
  end

  test "permitted_attributes excludes group_id for regular member" do
    policy = TestGroupManagedPolicy.new(@group_regular_user, @screen)
    attributes = policy.permitted_attributes

    refute_includes attributes, :group_id, "Regular member should not be able to edit group_id"
    assert_includes attributes, :name, "Should include entity-specific attributes"
  end

  test "permitted_attributes includes group_id for system admin" do
    policy = TestGroupManagedPolicy.new(@system_admin_user, @screen)
    attributes = policy.permitted_attributes

    assert_includes attributes, :group_id, "System admin should be able to edit group_id"
  end

  test "permitted_attributes includes group_id for new record if admin of any group" do
    policy = TestGroupManagedPolicy.new(@group_admin_user, Screen.new)
    attributes = policy.permitted_attributes

    assert_includes attributes, :group_id, "Should allow group_id for new records"
  end

  # Tests for can_edit_group?

  test "can_edit_group? is true for system admin" do
    policy = TestGroupManagedPolicy.new(@system_admin_user, @screen)
    assert policy.can_edit_group?, "System admin should be able to edit group"
  end

  test "can_edit_group? is true for group admin on existing record" do
    policy = TestGroupManagedPolicy.new(@group_admin_user, @screen)
    assert policy.can_edit_group?, "Group admin should be able to edit group"
  end

  test "can_edit_group? is false for regular member on existing record" do
    policy = TestGroupManagedPolicy.new(@group_regular_user, @screen)
    refute policy.can_edit_group?, "Regular member should not be able to edit group"
  end

  test "can_edit_group? is true for new record if user is logged in" do
    # For new records, any logged-in user can edit group (for UI purposes)
    # The actual permission check happens in can_create?
    policy = TestGroupManagedPolicy.new(@group_admin_user, Screen.new)
    assert policy.can_edit_group?, "Logged-in user should be able to set group on new record"
  end

  test "can_edit_group? is true for new record even if not admin" do
    # For new records, can_edit_group? just enables the UI field
    # The security check happens in can_create? which verifies group admin
    policy = TestGroupManagedPolicy.new(@non_group_user, Screen.new)
    assert policy.can_edit_group?, "Any logged-in user can see group field on new record (security check is in can_create?)"
  end

  test "can_edit_group? is false for nil user" do
    policy = TestGroupManagedPolicy.new(nil, @screen)
    refute policy.can_edit_group?, "Nil user should not be able to edit group"
  end

  # Tests for Scope

  test "Scope resolves to all entities" do
    scope = TestGroupManagedPolicy::Scope.new(@group_regular_user, Screen.all).resolve
    assert_equal Screen.all.to_a, scope.to_a, "Scope should return all entities"
  end

  test "Scope resolves to all entities for anonymous user" do
    scope = TestGroupManagedPolicy::Scope.new(nil, Screen.all).resolve
    assert_equal Screen.all.to_a, scope.to_a, "Scope should return all entities even for anonymous users"
  end

  # Test that entity_specific_attributes is required

  test "raises NotImplementedError if entity_specific_attributes not implemented" do
    policy_without_implementation = Class.new(ApplicationPolicy) do
      include GroupManagedPolicy
    end

    policy = policy_without_implementation.new(@group_admin_user, @screen)

    error = assert_raises(NotImplementedError) do
      policy.entity_specific_attributes
    end

    assert_match(/must implement #entity_specific_attributes/, error.message)
  end
end

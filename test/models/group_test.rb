require "test_helper"

class GroupTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    group = Group.new(name: "Test Group", description: "A test group")
    assert group.valid?
  end

  test "should require name" do
    group = Group.new(description: "A test group")
    assert_not group.valid?
    assert_includes group.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    existing_group = groups(:content_creators)
    group = Group.new(name: existing_group.name, description: "Different description")
    assert_not group.valid?
    assert_includes group.errors[:name], "has already been taken"
  end

  test "should identify system groups by name" do
    system_group = groups(:all_users)
    regular_group = groups(:content_creators)

    assert system_group.system_group?
    assert_not regular_group.system_group?
  end

  test "should find system admins group" do
     system_admins = groups(:system_administrators)
    assert_equal system_admins, Group.system_admins_group
  end

  test "should identify system administrators group" do
     system_admins = groups(:system_administrators)
    regular_group = groups(:content_creators)

    assert system_admins.system_admin_group?
    assert_not regular_group.system_admin_group?
  end

  test "should include system administrators in system groups" do
     system_admins = groups(:system_administrators)
    all_users = groups(:all_users)
    regular_group = groups(:content_creators)

    assert system_admins.system_group?
    assert all_users.system_group?
    assert_not regular_group.system_group?
  end

  test "should not destroy all users group" do
    system_group = groups(:all_users)
    assert_not system_group.destroy
    # The before_destroy callback prevents destruction but doesn't add errors
    # We just need to verify that destroy returns false
  end

  test "should not destroy system administrators group" do
     system_admins = groups(:system_administrators)
    assert_not system_admins.destroy
  end

  test "should allow destroying regular groups" do
    regular_group = groups(:content_creators)
    assert regular_group.destroy
  end

  test "should have many memberships" do
    group = groups(:content_creators)
    assert_respond_to group, :memberships
  end

  test "should have many users through memberships" do
    group = groups(:content_creators)
    assert_respond_to group, :users
    assert_includes group.users, users(:admin)
  end

  test "should not rename All Registered Users group" do
    all_users = groups(:all_users)
    original_name = all_users.name

    all_users.name = "Renamed Group"
    assert_not all_users.valid?
    assert_includes all_users.errors[:name], "cannot be changed for system groups"

    # Verify name was restored
    assert_equal original_name, all_users.name
  end

  test "should not rename System Administrators group" do
     system_admins = groups(:system_administrators)
    original_name = system_admins.name

    system_admins.name = "Super Admins"
    assert_not system_admins.valid?
    assert_includes system_admins.errors[:name], "cannot be changed for system groups"

    # Verify name was restored
    assert_equal original_name, system_admins.name
  end

  test "should allow renaming regular groups" do
    regular_group = groups(:content_creators)
    regular_group.name = "New Name"

    assert regular_group.valid?
    assert regular_group.save
  end

  test "database should prevent duplicate group names" do
    existing_group = groups(:content_creators)

    # Attempt to create a duplicate at the database level
    duplicate_group = Group.new(name: existing_group.name)

    assert_raises(ActiveRecord::RecordNotUnique) do
      duplicate_group.save(validate: false)  # Bypass validation to test DB constraint
    end
  end

  test "should prevent creating second All Registered Users group" do
    # The first one already exists from fixtures
    duplicate_group = Group.new(name: Group::REGISTERED_USERS_GROUP_NAME, description: "Duplicate")

    assert_not duplicate_group.valid?
    assert_includes duplicate_group.errors[:name], "has already been taken"
  end

  test "should prevent creating second System Administrators group" do
    # Create the first one
    Group.find_or_create_by!(name: Group::SYSTEM_ADMIN_GROUP_NAME)

    # Try to create a duplicate
    duplicate_group = Group.new(name: Group::SYSTEM_ADMIN_GROUP_NAME, description: "Duplicate")

    assert_not duplicate_group.valid?
    assert_includes duplicate_group.errors[:name], "has already been taken"
  end
end

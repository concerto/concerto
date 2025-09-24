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

  test "should not destroy system groups" do
    system_group = groups(:all_users)
    assert_not system_group.destroy
    # The before_destroy callback prevents destruction but doesn't add errors
    # We just need to verify that destroy returns false
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
end

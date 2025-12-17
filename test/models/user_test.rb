require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
  end

  test "requires first name" do
    @user.first_name = nil
    assert_not @user.valid?
    assert_includes @user.errors[:first_name], "can't be blank"
  end

  test "requires last name" do
    @user.last_name = nil
    assert_not @user.valid?
    assert_includes @user.errors[:last_name], "can't be blank"
  end

  test "full_name combines first and last name" do
    assert_equal "Admin User", @user.full_name
  end

  test "display_name uses full name when available" do
    assert_equal "Admin User", @user.display_name
  end

  test "display_name falls back to email when name not available" do
    @user.first_name = nil
    @user.last_name = nil
    assert_equal @user.email, @user.display_name
  end

  test "destroying user destroys associated contents" do
    # Create a dedicated user for this test
    test_user = User.create!(
      first_name: "Test",
      last_name: "User",
      email: "test@example.com",
      password: "password123"
    )

    # Create some content associated with the test user
    rich_text1 = RichText.create!(name: "Test Rich Text 1", duration: 30, text: "Test content 1", config: { 'render_as': "plaintext" }, user: test_user)
    rich_text2 = RichText.create!(name: "Test Rich Text 2", duration: 60, text: "Test content 2", config: { 'render_as': "plaintext" }, user: test_user)

    # Verify content exists and is associated with the user
    assert_equal 2, test_user.contents.count
    assert_includes test_user.contents, rich_text1
    assert_includes test_user.contents, rich_text2

    # Store content IDs to check they're destroyed
    rich_text1_id = rich_text1.id
    rich_text2_id = rich_text2.id

    # Destroy the user
    test_user.destroy

    # Verify associated content was also destroyed
    assert_nil Content.find_by(id: rich_text1_id)
    assert_nil Content.find_by(id: rich_text2_id)
  end

  test "system_admin? returns false for regular users" do
    regular_user = users(:regular)
    assert_not regular_user.system_admin?
  end

  test "system_admin? returns false for group admins" do
    admin_user = users(:admin)
    assert_not admin_user.system_admin?
  end

  test "system_admin? returns true for system administrators" do
    assert users(:system_admin).system_admin?
  end

  test "system_admin? returns true when user is regular member of system administrators group" do
    member_user = User.create!(
      first_name: "Member",
      last_name: "User",
      email: "member@example.com",
      password: "password123"
    )

    system_admins_group = groups(:system_administrators)
    Membership.create!(user: member_user, group: system_admins_group, role: :member)

    assert member_user.system_admin?
  end

  test "system_admin? returns false when system administrators group does not exist" do
    user_without_group = User.create!(
      first_name: "No",
      last_name: "Group",
      email: "nogroup@example.com",
      password: "password123"
    )

    # Ensure the system administrators group doesn't exist for this test
    Group.where(name: Group::SYSTEM_ADMIN_GROUP_NAME).destroy_all

    assert_not user_without_group.system_admin?
  end

  test "first human user is automatically added to system administrators group as admin" do
    # Clear all non-system users to ensure we're creating the first one
    User.where(is_system_user: [ nil, false ]).destroy_all

    first_user = User.create!(
      first_name: "First",
      last_name: "User",
      email: "first@example.com",
      password: "password123"
    )

    assert first_user.system_admin?, "First user should be a system administrator"

    system_admins_group = Group.find_by(name: Group::SYSTEM_ADMIN_GROUP_NAME)
    membership = Membership.find_by(user: first_user, group: system_admins_group)

    assert_not_nil membership, "First user should have a membership in system administrators group"
    assert_equal "admin", membership.role, "First user should be an admin, not just a member"
  end

  test "second human user is not automatically added to system administrators group" do
    # Clear all non-system users and create first user
    User.where(is_system_user: [ nil, false ]).destroy_all

    User.create!(
      first_name: "First",
      last_name: "User",
      email: "first@example.com",
      password: "password123"
    )

    # Create second user
    second_user = User.create!(
      first_name: "Second",
      last_name: "User",
      email: "second@example.com",
      password: "password123"
    )

    assert_not second_user.system_admin?, "Second user should not be a system administrator"
  end

  test "system user is not added to system administrators group even if first" do
    # Clear all users to ensure we're creating the very first one
    User.destroy_all

    system_user = User.create!(
      first_name: "System",
      last_name: "User",
      is_system_user: true
    )

    assert_not system_user.system_admin?, "System users should not be automatically made system administrators"
  end

  test "first human user after system users is added to system administrators group" do
    # Clear all users
    User.destroy_all

    # Create a system user first
    User.create!(
      first_name: "System",
      last_name: "User",
      is_system_user: true
    )

    # Create first human user
    first_human = User.create!(
      first_name: "First",
      last_name: "Human",
      email: "firsthuman@example.com",
      password: "password123"
    )

    assert first_human.system_admin?, "First human user should be a system administrator even if system users exist"
  end
end

require "test_helper"

class MembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group = groups(:content_creators)
    @system_group = groups(:all_users)
    @regular_user = users(:regular)
    @admin_user = users(:admin) # admin of content_creators
    @system_admin = users(:system_admin)
  end

  # Authorization tests
  test "unauthenticated users cannot manage memberships" do
    new_user = User.create!(
      email: "newuser@test.com",
      first_name: "New",
      last_name: "User",
      password: "password123"
    )

    post group_memberships_url(@group), params: {
      membership: { user_id: new_user.id, role: "member" }
    }
    assert_redirected_to new_user_session_path
  end

  test "only group admins can create memberships" do
    sign_in @regular_user
    new_user = User.create!(
      email: "newuser2@test.com",
      first_name: "New",
      last_name: "User2",
      password: "password123"
    )

    assert_no_difference("Membership.count") do
      post group_memberships_url(@group), params: {
        membership: { user_id: new_user.id, role: "member" }
      }
    end
    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "group admins can create memberships" do
    sign_in @admin_user
    new_user = User.create!(
      email: "newuser3@test.com",
      first_name: "New",
      last_name: "User3",
      password: "password123"
    )

    assert_difference("Membership.count") do
      post group_memberships_url(@group), params: {
        membership: { user_id: new_user.id, role: "member" }
      }
    end
    assert_redirected_to group_url(@group)
  end

  test "only group admins can update membership roles" do
    sign_in @regular_user
    membership = memberships(:regular_content_creator)
    original_role = membership.role

    patch group_membership_url(@group, membership), params: {
      membership: { role: "admin" }
    }
    assert_redirected_to root_path
    membership.reload
    assert_equal original_role, membership.role
  end

  test "group admins can update membership roles" do
    sign_in @admin_user
    membership = memberships(:regular_content_creator)

    patch group_membership_url(@group, membership), params: {
      membership: { role: "admin" }
    }
    assert_redirected_to group_url(@group)
    membership.reload
    assert_equal "admin", membership.role
  end

  test "users can remove themselves from groups" do
    sign_in @regular_user
    membership = memberships(:regular_content_creator)

    assert_difference("Membership.count", -1) do
      delete group_membership_url(@group, membership)
    end
    assert_redirected_to group_url(@group)
  end

  test "group admins can remove other members" do
    sign_in @admin_user
    membership = memberships(:regular_content_creator)

    assert_difference("Membership.count", -1) do
      delete group_membership_url(@group, membership)
    end
    assert_redirected_to group_url(@group)
  end

  test "non-admin members cannot remove other members" do
    sign_in @regular_user
    membership = memberships(:admin_content_creator) # Different user

    assert_no_difference("Membership.count") do
      delete group_membership_url(@group, membership)
    end
    assert_redirected_to root_path
  end

  test "group admins can set admin role when creating membership" do
    sign_in @admin_user
    new_user = User.create!(
      email: "newuser4@test.com",
      first_name: "New",
      last_name: "User4",
      password: "password123"
    )

    # Group admins can set role (including admin role)
    post group_memberships_url(@group), params: {
      membership: { user_id: new_user.id, role: "admin" }
    }
    assert_redirected_to group_url(@group)

    membership = Membership.find_by(user_id: new_user.id, group: @group)
    assert_equal "admin", membership.role
  end

  # Original functionality tests
  test "should create membership" do
    sign_in @admin_user
    # Create a new user not in the group
    new_user = User.create!(
      email: "newuser@test.com",
      first_name: "New",
      last_name: "User",
      password: "password123"
    )

    assert_difference("Membership.count") do
      post group_memberships_url(@group), params: {
        membership: {
          user_id: new_user.id,
          role: "member"
        }
      }
    end

    assert_redirected_to group_url(@group)
  end

  test "should not create duplicate membership" do
    sign_in @admin_user
    existing_membership = memberships(:admin_content_creator)

    assert_no_difference("Membership.count") do
      post group_memberships_url(@group), params: {
        membership: {
          user_id: existing_membership.user_id,
          role: "member"
        }
      }
    end

    assert_redirected_to group_url(@group)
  end

  test "should update membership role" do
    sign_in @admin_user
    membership = memberships(:regular_content_creator)

    patch group_membership_url(@group, membership), params: {
      membership: { role: "admin" }
    }

    assert_redirected_to group_url(@group)

    membership.reload
    assert_equal "admin", membership.role
  end

  test "should destroy membership" do
    sign_in @admin_user
    membership = memberships(:regular_content_creator)

    assert_difference("Membership.count", -1) do
      delete group_membership_url(@group, membership)
    end

    assert_redirected_to group_url(@group)
  end

  test "should not destroy membership from system group" do
    sign_in @admin_user
    system_membership = memberships(:admin_in_all_users)

    assert_no_difference("Membership.count") do
      delete group_membership_url(@system_group, system_membership)
    end

    assert_redirected_to group_url(@system_group)
  end

  test "should handle invalid user when creating membership" do
    sign_in @admin_user
    assert_no_difference("Membership.count") do
      post group_memberships_url(@group), params: {
        membership: {
          user_id: 99999, # Non-existent user
          role: "member"
        }
      }
    end

    assert_redirected_to group_url(@group)
  end
end

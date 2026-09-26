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

  test "group admin cannot move a membership into another group" do
    sign_in @admin_user
    membership = memberships(:regular_content_creator)
    system_admins = groups(:system_administrators)

    patch group_membership_url(@group, membership), params: {
      membership: { group_id: system_admins.id, user_id: @admin_user.id, role: "admin" }
    }

    membership.reload
    assert_equal @group, membership.group
    assert_equal @regular_user, membership.user
    refute @admin_user.reload.system_admin?
  end

  test "create ignores group_id and uses the group from the URL" do
    sign_in @admin_user
    new_user = User.create!(email: "moved@test.com", first_name: "New", last_name: "User", password: "password123")

    post group_memberships_url(@group), params: {
      membership: { user_id: new_user.id, group_id: groups(:system_administrators).id, role: "member" }
    }

    assert_equal [ @group.id ], new_user.memberships.where.not(group: @system_group).pluck(:group_id)
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

  test "last system admin cannot leave the System Administrators group" do
    sign_in @system_admin
    system_admins_group = groups(:system_administrators)
    membership = memberships(:system_admin_in_system_administrators)
    assert_equal 1, system_admins_group.users.count

    assert_no_difference("Membership.count") do
      delete group_membership_url(system_admins_group, membership)
    end

    assert_redirected_to group_url(system_admins_group)
    assert_match(/Cannot remove the last user/, flash[:alert])
  end

  test "system admin can add members to system group" do
    sign_in @system_admin
    new_user = User.create!(
      email: "newsysuser@test.com",
      first_name: "New",
      last_name: "SysUser",
      password: "password123"
    )
    system_admins_group = groups(:system_administrators)

    assert_difference("Membership.count") do
      post group_memberships_url(system_admins_group), params: {
        membership: { user_id: new_user.id, role: "admin" }
      }
    end
    assert_redirected_to group_url(system_admins_group)
  end

  test "system admin can remove members from system administrators group" do
    sign_in @system_admin
    sys_admins_group = groups(:system_administrators)
    extra_membership = Membership.create!(user: @admin_user, group: sys_admins_group, role: :admin)

    assert_difference("Membership.count", -1) do
      delete group_membership_url(sys_admins_group, extra_membership)
    end
    assert_redirected_to group_url(sys_admins_group)
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

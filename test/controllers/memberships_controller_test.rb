require "test_helper"

class MembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group = groups(:content_creators)
    @system_group = groups(:all_users)
    @user = users(:regular)
    @admin_user = users(:admin)
    sign_in @admin_user
  end

  test "should create membership" do
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
    membership = memberships(:regular_content_creator)

    patch group_membership_url(@group, membership), params: {
      membership: { role: "admin" }
    }

    assert_redirected_to group_url(@group)

    membership.reload
    assert_equal "admin", membership.role
  end

  test "should destroy membership" do
    membership = memberships(:regular_content_creator)

    assert_difference("Membership.count", -1) do
      delete group_membership_url(@group, membership)
    end

    assert_redirected_to group_url(@group)
  end

  test "should not destroy membership from system group" do
    system_membership = memberships(:admin_in_all_users)

    assert_no_difference("Membership.count") do
      delete group_membership_url(@system_group, system_membership)
    end

    assert_redirected_to group_url(@system_group)
  end

  test "should handle invalid user when creating membership" do
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

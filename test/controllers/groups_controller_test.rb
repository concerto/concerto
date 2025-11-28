require "test_helper"

class GroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group = groups(:content_creators)
    @system_group = groups(:all_users)
    @admin_user = users(:admin) # admin of content_creators group
    @regular_user = users(:regular)
    @system_admin = users(:system_admin)
  end

  # Authorization tests
  test "unauthenticated users cannot access groups index" do
    get groups_url
    assert_redirected_to new_user_session_path
  end

  test "unauthenticated users cannot view group details" do
    get group_url(@group)
    assert_redirected_to new_user_session_path
  end

  test "signed in users can view groups index" do
    sign_in @regular_user
    get groups_url
    assert_response :success
  end

  test "signed in users can view group details" do
    sign_in @regular_user
    get group_url(@group)
    assert_response :success
  end

  test "only system admins can create groups" do
    sign_in @regular_user
    get new_group_url
    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "system admins can create groups" do
    sign_in @system_admin
    get new_group_url
    assert_response :success
  end

  test "group admins can edit their groups" do
    sign_in @admin_user
    get edit_group_url(@group)
    assert_response :success
  end

  test "non-admin members cannot edit groups" do
    sign_in @regular_user
    get edit_group_url(@group)
    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "group admins can update their groups" do
    sign_in @admin_user
    patch group_url(@group), params: {
      group: { name: "Updated by Admin", description: "Updated" }
    }
    assert_redirected_to group_url(@group)
  end

  test "non-admin members cannot update groups" do
    sign_in @regular_user
    original_name = @group.name
    patch group_url(@group), params: {
      group: { name: "Hacked Name" }
    }
    assert_redirected_to root_path
    @group.reload
    assert_equal original_name, @group.name
  end

  test "only system admins can destroy groups" do
    sign_in @admin_user
    assert_no_difference("Group.count") do
      delete group_url(@group)
    end
    assert_redirected_to root_path
  end

  test "system admins can destroy groups" do
    sign_in @system_admin
    assert_difference("Group.count", -1) do
      delete group_url(@group)
    end
    assert_redirected_to groups_url
  end

  # Original functionality tests
  test "should get index" do
    sign_in @admin_user
    get groups_url
    assert_response :success
    assert_select "h1", "Groups"
  end

  test "should get new" do
    sign_in @system_admin
    get new_group_url
    assert_response :success
    assert_select "h1", "New Group"
  end

  test "should create group" do
    sign_in @system_admin
    assert_difference("Group.count") do
      post groups_url, params: {
        group: {
          name: "New Test Group",
          description: "A new test group description"
        }
      }
    end

    assert_redirected_to group_url(Group.last)
    follow_redirect!
    assert_select ".alert-success", /Group was successfully created/
  end

  test "should not create group with invalid data" do
    sign_in @system_admin
    assert_no_difference("Group.count") do
      post groups_url, params: { group: { name: "", description: "Invalid" } }
    end

    assert_response :unprocessable_entity
  end

  test "should show group" do
    sign_in @admin_user
    get group_url(@group)
    assert_response :success
    assert_select "h1", @group.name
  end

  test "should get edit" do
    sign_in @admin_user
    get edit_group_url(@group)
    assert_response :success
    assert_select "h1", "Edit Group - #{@group.name}"
  end

  test "should update group" do
    sign_in @admin_user
    patch group_url(@group), params: {
      group: {
        name: "Updated Name",
        description: "Updated description"
      }
    }
    assert_redirected_to group_url(@group)
    follow_redirect!
    assert_select ".alert-success", /Group was successfully updated/
  end

  test "should not update group with invalid data" do
    sign_in @admin_user
    patch group_url(@group), params: { group: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "should destroy group" do
    sign_in @system_admin
    assert_difference("Group.count", -1) do
      delete group_url(@group)
    end

    assert_redirected_to groups_url
    follow_redirect!
    assert_select ".alert-success", /Group was successfully deleted/
  end

  test "should not destroy system group" do
    sign_in @system_admin
    assert_no_difference("Group.count") do
      delete group_url(@system_group)
    end

    assert_redirected_to groups_url
  end
end

require "test_helper"

class GroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group = groups(:content_creators)
    @system_group = groups(:all_users)
    sign_in users(:admin)
  end

  test "should get index" do
    get groups_url
    assert_response :success
    assert_select "h1", "Groups"
  end

  test "should get new" do
    get new_group_url
    assert_response :success
    assert_select "h1", "New Group"
  end

  test "should create group" do
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
    assert_no_difference("Group.count") do
      post groups_url, params: { group: { name: "", description: "Invalid" } }
    end

    assert_response :unprocessable_entity
  end

  test "should show group" do
    get group_url(@group)
    assert_response :success
    assert_select "h1", @group.name
  end

  test "should get edit" do
    get edit_group_url(@group)
    assert_response :success
    assert_select "h1", "Edit Group - #{@group.name}"
  end

  test "should update group" do
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
    patch group_url(@group), params: { group: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "should destroy group" do
    assert_difference("Group.count", -1) do
      delete group_url(@group)
    end

    assert_redirected_to groups_url
    follow_redirect!
    assert_select ".alert-success", /Group was successfully deleted/
  end

  test "should not destroy system group" do
    assert_no_difference("Group.count") do
      delete group_url(@system_group)
    end

    assert_redirected_to groups_url
  end
end

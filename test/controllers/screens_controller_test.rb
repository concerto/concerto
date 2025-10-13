require "test_helper"

class ScreensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @screen = screens(:one)
    sign_in users(:admin)
  end

  teardown do
    sign_out :user
  end

  test "should get index" do
    get screens_url
    assert_response :success
  end

  test "should get new" do
    get new_screen_url
    assert_response :success
  end

  test "should create screen" do
    assert_difference("Screen.count") do
      post screens_url, params: { screen: { name: @screen.name, template_id: @screen.template_id, group_id: @screen.group_id } }
    end

    assert_redirected_to screen_url(Screen.last)
  end

  test "should show screen" do
    get screen_url(@screen)
    assert_response :success
  end

  test "should get edit" do
    get edit_screen_url(@screen)
    assert_response :success
  end

  test "should update screen" do
    patch screen_url(@screen), params: { screen: { name: @screen.name, template_id: @screen.template_id, group_id: @screen.group_id } }
    assert_redirected_to screen_url(@screen)
  end

  test "should destroy screen" do
    assert_difference("Screen.count", -1) do
      delete screen_url(@screen)
    end

    assert_redirected_to screens_url
  end

  test "should not get edit if not authorized" do
    sign_in users(:non_member)
    get edit_screen_url(@screen), headers: { "Referer" => screen_url(@screen) }
    assert_redirected_to screen_url(@screen)
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should not update screen when changing group without proper admin permissions" do
    sign_in users(:regular)

    # Use a group where regular user has no membership at all
    new_group = groups(:screen_two_owners)
    original_group = @screen.group

    # The group_id should be filtered out by permitted_attributes, so the update should succeed
    # but the group should not change
    patch screen_url(@screen), params: { screen: { name: "Updated Name", template_id: @screen.template_id, group_id: new_group.id } }
    assert_redirected_to screen_url(@screen)

    @screen.reload
    assert_equal "Updated Name", @screen.name
    assert_equal original_group.id, @screen.group_id  # Group should not have changed
  end

  test "should update screen when changing group with proper admin permissions" do
    sign_in users(:admin)
    patch screen_url(@screen), params: { screen: { name: @screen.name, template_id: @screen.template_id, group_id: groups(:content_creators).id } }
    assert_redirected_to screen_url(@screen)
    @screen.reload
    assert_equal groups(:content_creators).id, @screen.group_id
  end

  test "should not allow group_id in permitted_attributes for non-admin users" do
    sign_in users(:regular)
    policy = ScreenPolicy.new(users(:regular), @screen)
    refute_includes policy.permitted_attributes, :group_id
  end

  test "should allow group_id in permitted_attributes for admin users" do
    sign_in users(:admin)
    policy = ScreenPolicy.new(users(:admin), @screen)
    assert_includes policy.permitted_attributes, :group_id
  end

  test "regular group member should see disabled group selector when editing screen" do
    sign_in users(:regular)
    get edit_screen_url(@screen)
    assert_response :success

    # Check that the group selector is present but disabled
    assert_select "select[name='screen[group_id]'][disabled='disabled']"

    # Check that there's a hidden field with the current group_id
    assert_select "input[type='hidden'][name='screen[group_id]'][value='#{@screen.group_id}']"

    # Check that the help text indicates no permission to change group
    assert_select "p", text: /You don't have permission to change the group for this screen/
  end

  test "admin should see edit and delete buttons on screen show page" do
    sign_in users(:admin)
    get screen_url(@screen)
    assert_response :success

    # Check that edit and delete buttons are present
    assert_select "*", text: "Edit Screen"
    assert_select "*", text: "Delete Screen"
  end

  test "regular group member should see edit button but not delete button on screen show page" do
    sign_in users(:regular)
    get screen_url(@screen)
    assert_response :success

    # Check that edit button is present (regular members can edit)
    assert_select "*", text: "Edit Screen"

    # Check that delete button is NOT present (only admins can delete)
    assert_select "*", text: "Delete Screen", count: 0
  end

  test "non-member should not see edit or delete buttons on screen show page" do
    sign_in users(:non_member)
    get screen_url(@screen)
    assert_response :success

    # Check that edit and delete buttons are NOT present
    assert_select "*", text: "Edit Screen", count: 0
    assert_select "*", text: "Delete Screen", count: 0
  end

  test "signed out user should not see edit or delete buttons on screen show page" do
    # Explicitly sign out any user that might be signed in from setup
    sign_out :user
    get screen_url(@screen)
    assert_response :success

    # Check that edit and delete buttons are NOT present
    assert_select "*", text: "Edit Screen", count: 0
    assert_select "*", text: "Delete Screen", count: 0
  end

  test "admin should see new screen button on index page" do
    sign_in users(:admin)
    get screens_url
    assert_response :success

    # Check that new screen button is present
    assert_select "*", text: "New Screen"
  end

  test "regular group member should not see new screen button if they are not admin of any group" do
    sign_in users(:regular)
    get screens_url
    assert_response :success

    # Check that new screen button is NOT present (regular is only a member, not admin)
    assert_select "*", text: "New Screen", count: 0
  end

  test "non-member should not see new screen button on index page" do
    sign_in users(:non_member)
    get screens_url
    assert_response :success

    # Check that new screen button is NOT present
    assert_select "*", text: "New Screen", count: 0
  end

  test "signed out user should not see new screen button on index page" do
    sign_out :user
    get screens_url
    assert_response :success

    # Check that new screen button is NOT present
    assert_select "*", text: "New Screen", count: 0
  end
end

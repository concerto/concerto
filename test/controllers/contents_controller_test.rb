require "test_helper"

class ContentsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get contents_url
    assert_response :success
  end

  test "should get new when signed in" do
    sign_in users(:admin)
    get new_content_url
    assert_response :success
  end

  # Clock visibility tests on content type selection page
  test "screen managers see Clock option in Advanced section" do
    screen_manager = users(:admin)  # In screen_one_owners group
    sign_in screen_manager
    get new_content_url

    assert_response :success
    assert_select "h2", text: "Advanced", count: 1, message: "Advanced section should be visible"
    assert_select "a[href=?]", new_clock_path, count: 1, message: "Clock link should be present"
    assert_select "h3", text: "Add Clock", count: 1, message: "Clock option should be visible"
  end

  test "non-screen managers do not see Clock option" do
    non_screen_manager = users(:non_member)  # Only in all_users group
    sign_in non_screen_manager
    get new_content_url

    assert_response :success
    assert_select "h2", text: "Advanced", count: 0, message: "Advanced section should not be visible"
    assert_select "a[href=?]", new_clock_path, count: 0, message: "Clock link should not be present"
    assert_select "h3", text: "Add Clock", count: 0, message: "Clock option should not be visible"
  end

  test "system admins see Clock option in Advanced section" do
    system_admin = users(:system_admin)
    sign_in system_admin
    get new_content_url

    assert_response :success
    assert_select "h2", text: "Advanced", count: 1, message: "Advanced section should be visible"
    assert_select "a[href=?]", new_clock_path, count: 1, message: "Clock link should be present"
  end

  test "all users see standard content types" do
    non_screen_manager = users(:non_member)
    sign_in non_screen_manager
    get new_content_url

    assert_response :success
    assert_select "h3", text: "Add Graphic", count: 1
    assert_select "h3", text: "Add Text / HTML", count: 1
    assert_select "h3", text: "Add Video", count: 1
  end
end

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

  test "index ?q= narrows to matching active Content" do
    Search::Corpus.rebuild!
    rich_text = rich_texts(:active_ticker_text) # active scope, body contains "ticker"
    get contents_url, params: { q: "ticker" }
    assert_response :success
    assert_select "a[href='#{rich_text_path(rich_text)}']"
  end

  test "index ?q= composes with ?scope= so non-matching scope hides matches" do
    Search::Corpus.rebuild!
    rich_text = rich_texts(:active_ticker_text) # active, not upcoming
    get contents_url, params: { q: "ticker", scope: "upcoming" }
    assert_response :success
    assert_select "a[href='#{rich_text_path(rich_text)}']", count: 0
  end

  test "index ?q= with no matches renders empty grid" do
    Search::Corpus.rebuild!
    get contents_url, params: { q: "completelyabsentterm" }
    assert_response :success
    assert_select "a[href^='/videos/']", count: 0
    assert_select "a[href^='/rich_texts/']", count: 0
  end
end

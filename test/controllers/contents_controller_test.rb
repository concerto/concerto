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

  # Mine scope tests
  test "Mine tab is hidden for anonymous users" do
    get contents_url
    assert_response :success
    assert_select "a[href*='scope=mine']", count: 0
  end

  test "Mine tab is shown for signed-in users" do
    sign_in users(:admin)
    get contents_url
    assert_response :success
    assert_select "a[href*='scope=mine']"
  end

  test "scope=mine surfaces pending content owned by current user" do
    pending_content = RichText.create!(
      name: "My Pending", text: "Test", duration: 10, user: users(:non_member),
      config: { "render_as" => "plaintext" }
    )
    Submission.create!(content: pending_content, feed: feeds(:one)) # auto-pending for non-member

    sign_in users(:non_member)
    get contents_url, params: { scope: "mine" }
    assert_response :success
    assert_select "a[href='#{rich_text_path(pending_content)}']"
  end

  test "scope=mine surfaces unsubmitted content owned by current user" do
    draft = RichText.create!(
      name: "My Draft", text: "Test", duration: 10, user: users(:non_member),
      config: { "render_as" => "plaintext" }
    )

    sign_in users(:non_member)
    get contents_url, params: { scope: "mine" }
    assert_response :success
    assert_select "a[href='#{rich_text_path(draft)}']"
  end

  test "scope=mine does not include content owned by other users" do
    other_content = RichText.create!(
      name: "Someone Else's", text: "Test", duration: 10, user: users(:admin),
      config: { "render_as" => "plaintext" }
    )

    sign_in users(:non_member)
    get contents_url, params: { scope: "mine" }
    assert_response :success
    assert_select "a[href='#{rich_text_path(other_content)}']", count: 0
  end

  test "scope=mine falls back to active for anonymous users" do
    get contents_url, params: { scope: "mine" }
    # Title reflects the fallback scope
    assert_response :success
    assert_select "h1", text: "Active Content"
  end

  test "scope=mine ?q= matches owner's content by name" do
    needle = RichText.create!(
      name: "Findable Draft", text: "Body", duration: 10, user: users(:non_member),
      config: { "render_as" => "plaintext" }
    )
    decoy = RichText.create!(
      name: "Unrelated Draft", text: "Body", duration: 10, user: users(:non_member),
      config: { "render_as" => "plaintext" }
    )

    sign_in users(:non_member)
    get contents_url, params: { scope: "mine", q: "Findable" }
    assert_response :success
    assert_select "a[href='#{rich_text_path(needle)}']"
    assert_select "a[href='#{rich_text_path(decoy)}']", count: 0
  end
end

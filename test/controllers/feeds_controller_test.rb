require "test_helper"

class FeedsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @feed = feeds(:one)
    @system_admin = users(:system_admin)
  end

  test "should get index" do
    get feeds_url
    assert_response :success
  end

  test "should get new with system admin" do
    sign_in @system_admin
    get new_feed_url
    assert_response :success
  end

  test "should create feed with system admin" do
    sign_in @system_admin
    assert_difference("Feed.count") do
      post feeds_url, params: { feed: { description: @feed.description, name: @feed.name, group_id: @feed.group_id } }
    end

    assert_redirected_to feed_url(Feed.last)
  end

  test "should show feed" do
    get feed_url(@feed)
    assert_response :success
  end

  # Feed show status filtering tests
  test "anonymous user sees only approved content on feed show" do
    get feed_url(@feed)
    assert_response :success
    assert_select "a[href='#{graphic_path(graphics(:one))}']"
  end

  test "anonymous user does not see moderation toggle" do
    get feed_url(@feed)
    assert_response :success
    assert_select "div.bg-neutral-100 a[href*='status=pending']", count: 0
  end

  test "group member sees moderation toggle buttons" do
    sign_in users(:regular)
    get feed_url(@feed)
    assert_response :success
    assert_select "a[href*='status=approved']"
    assert_select "a[href*='status=pending']"
    assert_select "a[href*='status=rejected']"
  end

  test "group member with status=pending sees pending submissions" do
    sign_in users(:regular)
    get feed_url(@feed, status: "pending")
    assert_response :success
    # Should see the pending submission content name
    assert_select "a[href='#{rich_text_path(rich_texts(:plain_richtext))}']"
  end

  test "group member with status=rejected sees rejected submissions" do
    sign_in users(:regular)
    get feed_url(@feed, status: "rejected")
    assert_response :success
    assert_select "a[href='#{rich_text_path(rich_texts(:html_richtext))}']"
  end

  test "non-member does not see moderation toggle" do
    sign_in users(:non_member)
    get feed_url(@feed)
    assert_response :success
    assert_select "a[href*='status=pending']", count: 0
  end

  test "non-member with status=pending param still sees only approved content" do
    sign_in users(:non_member)
    get feed_url(@feed, status: "pending")
    assert_response :success
    # Should see approved content, not pending submissions
    assert_select "a[href='#{graphic_path(graphics(:one))}']"
    assert_select "a[href*='status=pending']", count: 0
  end

  # Scope filtering tests
  test "feed show defaults to active scope" do
    get feed_url(@feed)
    assert_response :success
    assert_select "a[href='#{graphic_path(graphics(:one))}']"
    # Should not show expired or upcoming content
    assert_select "a[href='#{graphic_path(graphics(:expired_graphic))}']", count: 0
    assert_select "a[href='#{graphic_path(graphics(:upcoming_graphic))}']", count: 0
  end

  test "feed show with scope=upcoming shows upcoming content" do
    get feed_url(@feed, scope: "upcoming")
    assert_response :success
    assert_select "a[href='#{graphic_path(graphics(:upcoming_graphic))}']"
    assert_select "a[href='#{graphic_path(graphics(:one))}']", count: 0
  end

  test "feed show with scope=expired shows expired content" do
    get feed_url(@feed, scope: "expired")
    assert_response :success
    assert_select "a[href='#{graphic_path(graphics(:expired_graphic))}']"
    assert_select "a[href='#{graphic_path(graphics(:one))}']", count: 0
  end

  test "feed show with invalid scope defaults to active" do
    get feed_url(@feed, scope: "invalid")
    assert_response :success
    assert_select "a[href='#{graphic_path(graphics(:one))}']"
  end

  test "scope toggle is visible to anonymous users" do
    get feed_url(@feed)
    assert_response :success
    assert_select "a[href*='scope=active']"
    assert_select "a[href*='scope=upcoming']"
    assert_select "a[href*='scope=expired']"
  end

  test "moderator scope links preserve status param" do
    sign_in users(:regular)
    get feed_url(@feed, status: "approved")
    assert_response :success
    assert_select "a[href*='status=approved'][href*='scope=active']"
  end

  # Mine status tests (any signed-in user can see their own submissions)
  test "anonymous user does not see Mine tab" do
    get feed_url(@feed)
    assert_response :success
    assert_select "a[href*='status=mine']", count: 0
  end

  test "signed-in user sees Mine tab even when they cannot moderate" do
    sign_in users(:non_member)
    get feed_url(@feed)
    assert_response :success
    assert_select "a[href*='status=mine']"
    # Non-member should not see moderator-only tabs
    assert_select "a[href*='status=pending']", count: 0
    assert_select "a[href*='status=rejected']", count: 0
  end

  test "status=mine surfaces pending submissions belonging to current user" do
    # users(:admin) owns plain_richtext, which has a pending submission to @feed.
    sign_in users(:admin)
    get feed_url(@feed, status: "mine")
    assert_response :success
    assert_select "a[href='#{rich_text_path(rich_texts(:plain_richtext))}']"
    # And the rejected one (html_richtext also owned by admin).
    assert_select "a[href='#{rich_text_path(rich_texts(:html_richtext))}']"
  end

  test "status=mine hides another user's submissions" do
    sign_in users(:non_member) # owns nothing in fixtures
    get feed_url(@feed, status: "mine")
    assert_response :success
    # Neither admin's pending nor rejected submission should appear.
    assert_select "a[href='#{rich_text_path(rich_texts(:plain_richtext))}']", count: 0
    assert_select "a[href='#{rich_text_path(rich_texts(:html_richtext))}']", count: 0
  end

  test "status=mine for anonymous user falls back to approved" do
    get feed_url(@feed, status: "mine")
    assert_response :success
    # Should show approved content, not enter Mine view.
    assert_select "a[href='#{graphic_path(graphics(:one))}']"
  end

  test "non-moderator does not see moderation actions on their pending submissions" do
    # non_member is not in @feed's group, so they cannot moderate.
    pending = RichText.create!(
      name: "Outsider Submission", text: "Test", duration: 10, user: users(:non_member),
      config: { "render_as" => "plaintext" }
    )
    Submission.create!(content: pending, feed: @feed)

    sign_in users(:non_member)
    get feed_url(@feed, status: "mine")
    assert_response :success
    assert_select "a[href='#{rich_text_path(pending)}']"
    # The Approve form posts to moderate_submission_path — it should not appear
    # for a non-moderator viewing their own submission via Mine.
    assert_select "form[action*='/moderate']", count: 0
  end

  test "should redirect STI feed to proper controller" do
    rss_feed = rss_feeds(:yahoo_rssfeed)
    get feed_url(rss_feed)
    assert_redirected_to rss_feed_url(rss_feed)
    assert_response :moved_permanently
  end

  test "should redirect STI feed with format" do
    rss_feed = rss_feeds(:yahoo_rssfeed)
    get feed_url(rss_feed, format: :json)
    assert_redirected_to rss_feed_url(rss_feed, format: :json)
    assert_response :moved_permanently
  end

  test "should redirect STI feed edit to proper controller" do
    sign_in @system_admin
    rss_feed = rss_feeds(:yahoo_rssfeed)
    get edit_feed_url(rss_feed)
    assert_redirected_to edit_rss_feed_url(rss_feed)
    assert_response :moved_permanently
  end

  test "should not allow updating STI feed via base controller" do
    sign_in @system_admin
    rss_feed = rss_feeds(:yahoo_rssfeed)
    patch feed_url(rss_feed), params: { feed: { name: "Updated name" } }
    assert_response :method_not_allowed
  end

  test "should not allow destroying STI feed via base controller" do
    sign_in @system_admin
    rss_feed = rss_feeds(:yahoo_rssfeed)
    assert_no_difference("Feed.count") do
      delete feed_url(rss_feed)
    end
    assert_response :method_not_allowed
  end

  test "should get edit with system admin" do
    sign_in @system_admin
    get edit_feed_url(@feed)
    assert_response :success
  end

  test "should update feed with system admin" do
    sign_in @system_admin
    patch feed_url(@feed), params: { feed: { description: @feed.description, name: @feed.name, group_id: @feed.group_id } }
    assert_redirected_to feed_url(@feed)
  end

  test "should destroy feed with system admin" do
    sign_in @system_admin
    assert_difference("Feed.count", -1) do
      delete feed_url(@feed)
    end

    assert_redirected_to feeds_url
  end

  # Authorization tests
  test "should allow group admin to create feed" do
    sign_in users(:admin)  # admin is a group admin
    assert_difference("Feed.count") do
      post feeds_url, params: { feed: { description: "New feed", name: "Test Feed", group_id: groups(:moderators).id } }
    end
    assert_redirected_to feed_url(Feed.last)
  end

  test "should not allow non-group-admin to create feed" do
    sign_in users(:non_member)  # not a group admin
    assert_no_difference("Feed.count") do
      post feeds_url, params: { feed: { description: "New feed", name: "Test Feed", group_id: groups(:moderators).id } }
    end
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should allow system admin to update feed" do
    sign_in @system_admin
    patch feed_url(@feed), params: { feed: { name: "Updated by system admin" } }
    assert_redirected_to feed_url(@feed)
    @feed.reload
    assert_equal "Updated by system admin", @feed.name
  end

  test "should allow group admin to update feed" do
    sign_in users(:admin)  # admin is admin of feed_one_owners
    patch feed_url(@feed), params: { feed: { name: "Updated by group admin" } }
    assert_redirected_to feed_url(@feed)
    @feed.reload
    assert_equal "Updated by group admin", @feed.name
  end

  test "should allow group member to update feed" do
    sign_in users(:regular)  # regular is member of feed_one_owners
    patch feed_url(@feed), params: { feed: { name: "Updated by group member" } }
    assert_redirected_to feed_url(@feed)
    @feed.reload
    assert_equal "Updated by group member", @feed.name
  end

  test "should not allow non-group member to update feed" do
    sign_in users(:non_member)  # non_member is not in feed_one_owners
    patch feed_url(@feed), params: { feed: { name: "Unauthorized update" } }
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
    @feed.reload
    assert_not_equal "Unauthorized update", @feed.name
  end

  test "should allow system admin to destroy feed" do
    sign_in @system_admin
    assert_difference("Feed.count", -1) do
      delete feed_url(@feed)
    end
    assert_redirected_to feeds_url
  end

  test "should allow group admin to destroy feed" do
    sign_in users(:admin)  # admin is admin of feed_one_owners
    assert_difference("Feed.count", -1) do
      delete feed_url(@feed)
    end
    assert_redirected_to feeds_url
  end

  test "should not allow group member to destroy feed" do
    sign_in users(:regular)  # regular is only a member, not admin
    assert_no_difference("Feed.count") do
      delete feed_url(@feed)
    end
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should not allow non-group member to destroy feed" do
    sign_in users(:non_member)  # non_member is not in feed_one_owners
    assert_no_difference("Feed.count") do
      delete feed_url(@feed)
    end
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "index ?q= narrows to matching Feed names" do
    Search::Corpus.rebuild!
    rss = rss_feeds(:yahoo_rssfeed)
    get feeds_url, params: { q: "yahoo" }
    assert_response :success
    assert_select "a[href='#{rss_feed_path(rss)}']"
    # Other feeds should be filtered out
    assert_select "a[href='#{feed_path(@feed)}']", count: 0
  end

  test "index ?q= with no matches renders empty list" do
    Search::Corpus.rebuild!
    get feeds_url, params: { q: "completelyabsentterm" }
    assert_response :success
    assert_select "a[href='#{feed_path(@feed)}']", count: 0
  end
end

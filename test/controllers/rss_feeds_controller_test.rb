require "test_helper"

class RssFeedsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @rss_feed = rss_feeds(:yahoo_rssfeed)
    @system_admin = users(:system_admin)
  end

  test "should get new with group admin" do
    sign_in users(:admin)  # group admin
    get new_rss_feed_url
    assert_response :success
  end

  test "should create rss_feed with group admin" do
    sign_in users(:admin)  # group admin
    assert_difference("RssFeed.count") do
      post rss_feeds_url, params: { rss_feed: { description: @rss_feed.description, name: @rss_feed.name, url: @rss_feed.url,
        formatter: @rss_feed.formatter } }
    end

    assert_redirected_to rss_feed_url(RssFeed.last)
  end

  test "should show rss_feed" do
    get rss_feed_url(@rss_feed)
    assert_response :success
  end

  test "should get edit with system admin" do
    sign_in @system_admin
    get edit_rss_feed_url(@rss_feed)
    assert_response :success
  end

  test "should update rss_feed with system admin" do
    sign_in @system_admin
    patch rss_feed_url(@rss_feed), params: { rss_feed: { description: @rss_feed.description, name: @rss_feed.name, url: @rss_feed.url,
      formatter: @rss_feed.formatter } }
    assert_redirected_to rss_feed_url(@rss_feed)
  end

  test "should destroy rss_feed with system admin" do
    sign_in @system_admin
    assert_difference("RssFeed.count", -1) do
      delete rss_feed_url(@rss_feed)
    end

    assert_redirected_to feeds_url
  end

  test "should cleanup unused content with system admin" do
    sign_in @system_admin
    delete cleanup_rss_feed_url(@rss_feed)
    assert_redirected_to rss_feed_url(@rss_feed)
  end

  # Authorization tests
  test "should allow group admin to create rss_feed" do
    sign_in users(:admin)  # admin is a group admin
    assert_difference("RssFeed.count") do
      post rss_feeds_url, params: { rss_feed: { description: "RSS Test Feed", name: "Test RSS Feed", url: "https://example.com/rss", formatter: "headlines" } }
    end
    assert_redirected_to rss_feed_url(RssFeed.last)
  end

  test "should not allow non-group-admin to create rss_feed" do
    sign_in users(:non_member)  # not a group admin
    assert_no_difference("RssFeed.count") do
      post rss_feeds_url, params: { rss_feed: { description: "RSS Test Feed", name: "Test RSS Feed", url: "https://example.com/rss", formatter: "headlines" } }
    end
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should allow system admin to update rss_feed" do
    sign_in @system_admin
    patch rss_feed_url(@rss_feed), params: { rss_feed: { name: "Updated by system admin" } }
    assert_redirected_to rss_feed_url(@rss_feed)
    @rss_feed.reload
    assert_equal "Updated by system admin", @rss_feed.name
  end

  test "should not allow non-system-admin to update rss_feed" do
    sign_in users(:admin)  # even group admin can't update (limitation until #511)
    patch rss_feed_url(@rss_feed), params: { rss_feed: { name: "Unauthorized update" } }
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
    @rss_feed.reload
    assert_not_equal "Unauthorized update", @rss_feed.name
  end

  test "should allow system admin to destroy rss_feed" do
    sign_in @system_admin
    assert_difference("RssFeed.count", -1) do
      delete rss_feed_url(@rss_feed)
    end
    assert_redirected_to feeds_url
  end

  test "should not allow non-system-admin to destroy rss_feed" do
    sign_in users(:admin)  # even group admin can't destroy (limitation until #511)
    assert_no_difference("RssFeed.count") do
      delete rss_feed_url(@rss_feed)
    end
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should allow system admin to refresh rss_feed" do
    sign_in @system_admin
    # Just test that authorized user can access the action
    # The actual refresh behavior is tested in model tests
    assert_nothing_raised do
      get refresh_rss_feed_url(@rss_feed)
    end
    assert_redirected_to rss_feed_url(@rss_feed)
  end

  test "should not allow non-system-admin to refresh rss_feed" do
    sign_in users(:admin)  # even group admin can't refresh (limitation until #511)
    get refresh_rss_feed_url(@rss_feed)
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should allow system admin to cleanup rss_feed" do
    sign_in @system_admin
    # Just test that authorized user can access the action
    # The actual cleanup behavior is tested in model tests
    delete cleanup_rss_feed_url(@rss_feed)
    assert_redirected_to rss_feed_url(@rss_feed)
  end

  test "should not allow non-system-admin to cleanup rss_feed" do
    sign_in users(:admin)  # even group admin can't cleanup (limitation until #511)
    delete cleanup_rss_feed_url(@rss_feed)
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end
end

require "test_helper"

class RssFeedsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @rss_feed = rss_feeds(:yahoo_rssfeed)
  end

  test "should get new" do
    get new_rss_feed_url
    assert_response :success
  end

  test "should create rss_feed" do
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

  test "should get edit" do
    get edit_rss_feed_url(@rss_feed)
    assert_response :success
  end

  test "should update rss_feed" do
    patch rss_feed_url(@rss_feed), params: { rss_feed: { description: @rss_feed.description, name: @rss_feed.name, url: @rss_feed.url,
      formatter: @rss_feed.formatter } }
    assert_redirected_to rss_feed_url(@rss_feed)
  end

  test "should destroy rss_feed" do
    assert_difference("RssFeed.count", -1) do
      delete rss_feed_url(@rss_feed)
    end

    assert_redirected_to feeds_url
  end

  test "should cleanup unused content" do
    # Create some unused content by stubbing the refresh process
    @rss_feed.stub :new_items, [ "Item 1", "Item 2" ] do
      @rss_feed.refresh
    end

    @rss_feed.stub :new_items, [ "Updated Item 1" ] do
      @rss_feed.refresh
    end

    # Should have unused content
    assert @rss_feed.content.unused.count > 0

    delete cleanup_rss_feed_url(@rss_feed)

    assert_redirected_to rss_feed_url(@rss_feed)
    assert_equal 0, @rss_feed.content.unused.count
  end
end

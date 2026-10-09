require "test_helper"
require "minitest/mock"

class RssFeedTest < ActiveSupport::TestCase
  setup do
    @feed = rss_feeds(:yahoo_rssfeed)
  end

  test "parses headlines from a simple RSS feed" do
    mock_file = File.read("test/support/basic_rss_feed.xml")

    mock = Minitest::Mock.new
    mock.expect(:scheme, "https")
    mock.expect(:host, "news.yahoo.com")
    mock.expect(:open, mock_file)

    URI.stub(:parse, mock) do
      items = @feed.new_items
      assert_equal items.length, 2

      assert_equal items[0], [
        "<h1>Yahoo News - Latest News &amp; Headlines</h1>",
        "<h2>Item 1 Title</h2>",
        "<h2>Item 2 Title &amp; is fancy</h2>",
        "<h2>Item 3 Title</h2>",
        "<h2>Item 4 Title</h2>",
        "<h2>Item 5 Title</h2>" ].join()

        assert_equal items[1], [
          "<h1>Yahoo News - Latest News &amp; Headlines</h1>",
          "<h2>Item 6 Title</h2>",
          "<h2>Item 7 Title</h2>",
          "<h2>Item 8 Title</h2>",
          "<h2>Item 9 Title</h2>",
          "<h2>Item 10 Title</h2>" ].join()
    end
    mock.verify
  end

  test "creates new content items when there are none" do
    feed = RssFeed.create(group: groups(:system_administrators))

    assert_equal feed.content.length, 0

    mock_items = [ "Item 1", "Item 2" ]
    feed.stub :new_items, mock_items do
      feed.refresh
    end

    assert_equal feed.content.length, 2

    assert_equal feed.content[0].text, mock_items[0]
    assert_nil feed.content[0].end_time

    assert_equal feed.content[1].text, mock_items[1]
    assert_nil feed.content[1].end_time
  end

  test "updates existing and expires unneeded content items" do
    feed = RssFeed.create(group: groups(:system_administrators))

    original_items = [ "Item 1", "Item 2" ]
    feed.stub :new_items, original_items do
      feed.refresh
    end

    # At this point, the feed should have 2 active pieces of content
    mock_items = [ "Item 3" ]
    feed.stub :new_items, mock_items do
      feed.refresh
    end

    content = feed.content.sort_by { |c| c.name }

    assert_equal content[0].text, mock_items[0]
    assert_equal content[0].render_as, "html"
    assert_nil content[0].end_time

    assert content[1].name.include?("unused")
    assert_equal content[1].render_as, "html"
    assert_empty content[1].text
    assert_operator content[1].end_time, :<, Time.now
  end

  test "parses details from a simple RSS feed" do
    @feed.formatter = "details"
    mock_file = File.read("test/support/basic_rss_feed.xml")

    mock = Minitest::Mock.new
    mock.expect(:scheme, "https")
    mock.expect(:host, "news.yahoo.com")
    mock.expect(:open, mock_file)

    URI.stub(:parse, mock) do
      items = @feed.new_items
      assert_equal items.length, 10

      assert_equal items[0], [
        "<h1>Item 1 Title</h1>",
        "<p>Description for Item 1</p>"
      ].join()

      assert_equal items[1], [
        "<h1>Item 2 Title &amp; is fancy</h1>",
        "<p>Description for Item 2 &amp; too!</p>"
      ].join()
    end
    mock.verify
  end

  test "refresh creates used and unused content correctly" do
    feed = RssFeed.create(name: "Test Feed", group: groups(:system_administrators))

    # Create content then refresh with fewer items to create unused content
    feed.stub :new_items, [ "Item 1", "Item 2", "Item 3" ] do
      feed.refresh
    end

    feed.stub :new_items, [ "Updated Item 1" ] do
      feed.refresh
    end

    # Should have 1 used, 2 unused content items
    assert_equal 1, feed.content.used.count
    assert_equal 2, feed.content.unused.count

    # Used content should have text, unused should be empty with "(unused)" name
    assert_equal "Updated Item 1", feed.content.used.first.text
    feed.content.unused.each do |content|
      assert_empty content.text
      assert content.name.include?("(unused)")
    end
  end

  test "cleanup_unused_content deletes only unused content" do
    feed = RssFeed.create(name: "Test Feed", group: groups(:system_administrators))

    # Create content then refresh to create unused content
    feed.stub :new_items, [ "Item 1", "Item 2", "Item 3" ] do
      feed.refresh
    end

    feed.stub :new_items, [ "Updated Item 1" ] do
      feed.refresh
    end

    # Should have 1 used, 2 unused content items
    assert_equal 1, feed.content.used.count
    assert_equal 2, feed.content.unused.count

    # Cleanup unused content
    feed.cleanup_unused_content

    # Should have 1 used, 0 unused content items
    assert_equal 1, feed.content.used.count
    assert_equal 0, feed.content.unused.count
    assert_equal 1, feed.content.count
  end

  test "destroys all associated content when RSS feed is deleted" do
    feed = RssFeed.create(name: "Test Feed", group: groups(:system_administrators))

    # Create some content for the feed
    feed.stub :new_items, [ "Item 1", "Item 2", "Item 3" ] do
      feed.refresh
    end

    # Verify content was created
    assert_equal 3, feed.content.count
    content_ids = feed.content.pluck(:id)

    # Verify content exists before deletion
    content_ids.each do |content_id|
      assert_not_nil RichText.find_by(id: content_id), "Content #{content_id} should exist before deletion"
    end

    # Delete the RSS feed
    feed.destroy

    # Verify all associated content was destroyed
    content_ids.each do |content_id|
      assert_nil RichText.find_by(id: content_id), "Content #{content_id} should be destroyed after feed deletion"
    end
  end

  test "parses ticker format from RSS feed with HTML stripping" do
    @feed.formatter = "ticker"
    mock_file = File.read("test/support/basic_rss_feed.xml")

    mock = Minitest::Mock.new
    mock.expect(:scheme, "https")
    mock.expect(:host, "news.yahoo.com")
    mock.expect(:open, mock_file)

    URI.stub(:parse, mock) do
      items = @feed.new_items
      assert_equal 10, items.length

      # Ticker format should strip HTML and newlines, keeping only plain text titles
      assert_equal "Item 1 Title", items[0]
      assert_equal "Item 2 Title & is fancy", items[1]
      assert_equal "Item 3 Title", items[2]
    end
    mock.verify
  end

  test "ticker format creates plaintext RichText content" do
    feed = RssFeed.create(name: "Ticker Feed", group: groups(:system_administrators))
    feed.formatter = "ticker"

    mock_items = [ "Ticker Item 1", "Ticker Item 2" ]
    feed.stub :new_items, mock_items do
      feed.refresh
    end

    assert_equal 2, feed.content.count

    # All content should be plaintext for ticker format
    feed.content.each do |content|
      assert content.plaintext?, "Ticker content should be plaintext"
    end

    # Verify content text
    assert_equal "Ticker Item 1", feed.content.first.text
    assert_equal "Ticker Item 2", feed.content.last.text
  end

  test "new_items refuses a feed URL that resolves to a loopback address" do
    # WebMock allows localhost by default, so stub a response that WOULD
    # succeed if the request were made, and prove via assert_not_requested
    # that the guard stopped it before WebMock ever saw it.
    stub_request(:get, "http://127.0.0.1:18999/")
      .to_return(status: 200, body: File.read("test/support/basic_rss_feed.xml"))

    feed = RssFeed.create!(group: groups(:system_administrators), config: { url: "http://127.0.0.1:18999/", formatter: "headlines" })

    assert_equal [], feed.new_items
    assert_not_requested :get, "http://127.0.0.1:18999/"
  end

  test "new_items refuses a feed URL that resolves to a private RFC1918 address" do
    feed = RssFeed.create!(group: groups(:system_administrators), config: { url: "http://10.0.0.5/feed.xml", formatter: "headlines" })

    # No stub for this non-localhost host: an unguarded fetch would hit
    # WebMock's disable_net_connect! and raise, rather than returning [].
    assert_equal [], feed.new_items
  end

  test "safe_external_uri? allows ordinary public https URLs" do
    assert RssFeed.safe_external_uri?(URI.parse("https://news.yahoo.com/rss/all"))
  end

  test "safe_external_uri? rejects loopback, private, and link-local addresses" do
    refute RssFeed.safe_external_uri?(URI.parse("http://127.0.0.1/"))
    refute RssFeed.safe_external_uri?(URI.parse("http://10.0.0.5/"))
    refute RssFeed.safe_external_uri?(URI.parse("http://192.168.1.1/"))
    refute RssFeed.safe_external_uri?(URI.parse("http://169.254.169.254/"))
  end
end

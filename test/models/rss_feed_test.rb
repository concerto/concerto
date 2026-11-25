require "test_helper"

class RssFeedTest < ActiveSupport::TestCase
  setup do
    @feed = rss_feeds(:yahoo_rssfeed)
  end

  test "parses headlines from a simple RSS feed" do
    mock_file = File.read("test/support/basic_rss_feed.xml")
    stub_request(:get, @feed.url)
      .to_return(status: 200, body: mock_file, headers: { "Content-Type" => "application/rss+xml" })

    items = @feed.new_items
    assert_equal 2, items.length

    assert_equal items[0], [
      "<h1>Yahoo News - Latest News &amp; Headlines</h1>",
      "<h2>Item 1 Title</h2>",
      "<h2>Item 2 Title &amp; is fancy</h2>",
      "<h2>Item 3 Title</h2>",
      "<h2>Item 4 Title</h2>",
      "<h2>Item 5 Title</h2>" ].join

    assert_equal items[1], [
      "<h1>Yahoo News - Latest News &amp; Headlines</h1>",
      "<h2>Item 6 Title</h2>",
      "<h2>Item 7 Title</h2>",
      "<h2>Item 8 Title</h2>",
      "<h2>Item 9 Title</h2>",
      "<h2>Item 10 Title</h2>" ].join
  end

  test "creates new content items when there are none" do
    feed = RssFeed.create!(url: "https://example.com/rss", group: groups(:system_administrators))

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
    feed = RssFeed.create!(url: "https://example.com/rss", group: groups(:system_administrators))

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

  test "numbers newly added content items starting after existing items" do
    feed = RssFeed.create!(name: "News", url: "https://example.com/rss", group: groups(:system_administrators))

    feed.stub :new_items, [ "Item 1", "Item 2" ] do
      feed.refresh
    end

    feed.stub :new_items, [ "Item 1", "Item 2", "Item 3", "Item 4" ] do
      feed.refresh
    end

    names = feed.content.order(:id).pluck(:name)
    assert_equal [ "News (1)", "News (2)", "News (3)", "News (4)" ], names
  end

  test "refresh preserves user-submitted non-RichText and RichText content" do
    feed = RssFeed.create!(name: "News", url: "https://example.com/rss", group: groups(:system_administrators))

    user_graphic = Graphic.create!(name: "User Poster", duration: 15, user: users(:regular))
    user_video = Video.create!(name: "User Video", config: { url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ" }, user: users(:regular))
    user_text = RichText.create!(name: "User Announcement", text: "Hello everyone", render_as: "plaintext", user: users(:regular))

    feed.submissions.create!(content: user_graphic)
    feed.submissions.create!(content: user_video)
    feed.submissions.create!(content: user_text)

    # Refresh with 2 items, then refresh with 1 item to trigger expiration path
    feed.stub :new_items, [ "RSS Item 1", "RSS Item 2" ] do
      assert_nothing_raised { feed.refresh }
    end

    feed.stub :new_items, [ "RSS Item 1 Updated" ] do
      assert_nothing_raised { feed.refresh }
    end

    user_graphic.reload
    user_video.reload
    user_text.reload

    assert_equal "User Poster", user_graphic.name
    assert_nil user_graphic.end_time
    assert_equal "User Video", user_video.name
    assert_nil user_video.end_time
    assert_equal "User Announcement", user_text.name
    assert_equal "Hello everyone", user_text.text
    assert_equal "plaintext", user_text.render_as
    assert_nil user_text.end_time

    # System-owned RSS items were updated and expired properly
    system_user = users(:system_user)
    system_items = feed.content.where(user: system_user).order(:id)
    assert_equal 2, system_items.count
    assert_equal "RSS Item 1 Updated", system_items.first.text
    assert_includes system_items.last.name, "(unused)"
  end

  test "parses details from a simple RSS feed" do
    @feed.formatter = "details"
    mock_file = File.read("test/support/basic_rss_feed.xml")
    stub_request(:get, @feed.url)
      .to_return(status: 200, body: mock_file, headers: { "Content-Type" => "application/rss+xml" })

    items = @feed.new_items
    assert_equal 10, items.length

    assert_equal items[0], [
      "<h1>Item 1 Title</h1>",
      "<p>Description for Item 1</p>"
    ].join

    assert_equal items[1], [
      "<h1>Item 2 Title &amp; is fancy</h1>",
      "<p>Description for Item 2 &amp; too!</p>"
    ].join
  end

  test "refresh creates used and unused content correctly" do
    feed = RssFeed.create!(name: "Test Feed", url: "https://example.com/rss", group: groups(:system_administrators))

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

  test "cleanup_unused_content deletes only unused system-generated content" do
    feed = RssFeed.create!(name: "Test Feed", url: "https://example.com/rss", group: groups(:system_administrators))

    # Create content then refresh to create unused content
    feed.stub :new_items, [ "Item 1", "Item 2", "Item 3" ] do
      feed.refresh
    end

    feed.stub :new_items, [ "Updated Item 1" ] do
      feed.refresh
    end

    # Add a manually submitted expired item that mimics the unused name pattern
    manual_item = RichText.create!(
      name: "Manual (unused)",
      text: "",
      render_as: "plaintext",
      end_time: 1.hour.ago,
      user: users(:regular)
    )
    feed.submissions.create!(content: manual_item)

    # Should have 1 used, 3 unused (2 system + 1 manual)
    assert_equal 1, feed.content.used.count
    assert_equal 3, feed.content.unused.count

    # Cleanup unused content
    feed.cleanup_unused_content

    # System unused items are removed; manual item is preserved
    assert_equal 1, feed.content.used.count
    assert_equal 1, feed.content.unused.count
    assert RichText.exists?(manual_item.id)
  end

  test "destroys all associated content when RSS feed is deleted" do
    feed = RssFeed.create!(name: "Test Feed", url: "https://example.com/rss", group: groups(:system_administrators))

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
    stub_request(:get, @feed.url)
      .to_return(status: 200, body: mock_file, headers: { "Content-Type" => "application/rss+xml" })

    items = @feed.new_items
    assert_equal 10, items.length

    # Ticker format should strip HTML and newlines, keeping only plain text titles
    assert_equal "Item 1 Title", items[0]
    assert_equal "Item 2 Title & is fancy", items[1]
    assert_equal "Item 3 Title", items[2]
  end

  test "ticker format creates plaintext RichText content" do
    feed = RssFeed.create!(name: "Ticker Feed", url: "https://example.com/rss", group: groups(:system_administrators))
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

  test "requires an anchored http or https url and allows internal/private hosts" do
    feed = RssFeed.new(name: "Feed", group: groups(:system_administrators), formatter: "headlines")

    [
      "",
      "ftp://example.com/rss",
      "file:///etc/passwd",
      "javascript:alert(1)//https://example.com",
      "prefix https://example.com/rss",
      "https://",
      "http://exa mple.com/rss"
    ].each do |bad_url|
      feed.url = bad_url
      assert_not feed.valid?, "Expected #{bad_url.inspect} to be invalid"
    end

    # External and internal/private LAN URLs are both permitted (#2002)
    [
      "https://example.com/rss",
      "http://intranet-news/feed.xml",
      "http://192.168.1.50:8080/rss.xml",
      "http://127.0.0.1:3000/rss"
    ].each do |good_url|
      feed.url = good_url
      assert feed.valid?, "Expected #{good_url.inspect} to be valid"
    end
  end

  test "follows redirects up to the cap and rejects redirect loops or non-http targets" do
    mock_file = File.read("test/support/basic_rss_feed.xml")
    stub_request(:get, @feed.url)
      .to_return(status: 302, headers: { "Location" => "/rss/redirected" })
    stub_request(:get, "https://news.yahoo.com/rss/redirected")
      .to_return(status: 200, body: mock_file, headers: { "Content-Type" => "application/rss+xml" })

    assert_equal 2, @feed.new_items.length

    # Redirect loop exceeds MAX_REDIRECTS
    stub_request(:get, @feed.url)
      .to_return(status: 302, headers: { "Location" => @feed.url })

    error = assert_raises(RssFeed::FetchError) { @feed.new_items }
    assert_match(/too many redirects/i, error.message)

    # Redirect to non-http scheme is rejected
    stub_request(:get, @feed.url)
      .to_return(status: 302, headers: { "Location" => "file:///etc/passwd" })

    error = assert_raises(RssFeed::FetchError) { @feed.new_items }
    assert_match(/invalid rss feed url/i, error.message)
  end

  test "rejects responses exceeding MAX_RESPONSE_SIZE via Content-Length or streamed body" do
    stub_request(:get, @feed.url)
      .to_return(status: 200, body: "", headers: { "Content-Length" => (RssFeed::MAX_RESPONSE_SIZE + 1).to_s })

    error = assert_raises(RssFeed::FetchError) { @feed.new_items }
    assert_match(/maximum size/i, error.message)

    oversized_body = "x" * (RssFeed::MAX_RESPONSE_SIZE + 1)
    stub_request(:get, @feed.url)
      .to_return(status: 200, body: oversized_body)

    error = assert_raises(RssFeed::FetchError) { @feed.new_items }
    assert_match(/maximum size/i, error.message)
  end

  test "raises FetchError on non-success HTTP status" do
    stub_request(:get, @feed.url).to_return(status: 503, body: "Unavailable")

    error = assert_raises(RssFeed::FetchError) { @feed.new_items }
    assert_match(/503/, error.message)
  end
end

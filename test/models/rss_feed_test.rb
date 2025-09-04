require "test_helper"
require "minitest/mock"

class RssFeedTest < ActiveSupport::TestCase
  setup do
    @feed = rss_feeds(:yahoo_rssfeed)
  end

  test "parses headlines from a simple RSS feed" do
    mock_file = File.read("test/support/basic_rss_feed.xml")

    mock = Minitest::Mock.new
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
    feed = RssFeed.create()

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
    feed = RssFeed.create()

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
    assert_nil content[0].end_time

    assert content[1].name.include?("unused")
    assert_empty content[1].text
    assert_operator content[1].end_time, :<, Time.now
  end

  test "parses details from a simple RSS feed" do
    @feed.formatter = "details"
    mock_file = File.read("test/support/basic_rss_feed.xml")

    mock = Minitest::Mock.new
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
    feed = RssFeed.create(name: "Test Feed")

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
    feed = RssFeed.create(name: "Test Feed")

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
    feed = RssFeed.create(name: "Test Feed")

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
end

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
        "<h1>Yahoo News - Latest News  Headlines</h1>",
        "<h2>Item 1 Title</h2>",
        "<h2>Item 2 Title</h2>",
        "<h2>Item 3 Title</h2>",
        "<h2>Item 4 Title</h2>",
        "<h2>Item 5 Title</h2>" ].join()

        assert_equal items[1], [
          "<h1>Yahoo News - Latest News  Headlines</h1>",
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
end

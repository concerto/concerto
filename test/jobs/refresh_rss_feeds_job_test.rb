require "test_helper"

class RefreshRssFeedsJobTest < ActiveJob::TestCase
  setup do
    # Clear the database before each test
    RssFeed.destroy_all

    # Create test feeds with different scenarios
    @feed_due_for_refresh = RssFeed.create!(
      name: "Due for refresh",
      url: "https://news.yahoo.com/rss/us",
      group: groups(:system_administrators)
    )
    @feed_due_for_refresh.last_refreshed = 2.hours.ago
    @feed_due_for_refresh.refresh_interval = 1.hour
    @feed_due_for_refresh.save!

    @feed_not_due = RssFeed.create!(
      name: "Not due yet",
      group: groups(:system_administrators)
    )
    @feed_not_due.last_refreshed = 30.minutes.ago
    @feed_not_due.refresh_interval = 1.hour
    @feed_not_due.save!

    @feed_never_refreshed = RssFeed.create!(
      name: "Never refreshed",
      group: groups(:system_administrators)
    )

    @feed_custom_interval = RssFeed.create!(
      name: "Custom interval",
      group: groups(:system_administrators)
    )
    @feed_custom_interval.last_refreshed = 3.hours.ago
    @feed_custom_interval.refresh_interval = 4.hours
    @feed_custom_interval.save!

    # Setup tracking for feed refreshes
    @refreshed_feeds = []

    # Override the refresh method to track calls
    RssFeed.class_eval do
      alias_method :original_refresh, :refresh

      define_method(:refresh) do
        # Track which feeds are refreshed
        RefreshRssFeedsJobTest.refreshed_feeds << self.id
        # Update last_refreshed as the real method would
        self.last_refreshed = Time.now
        self.save!
      end
    end
  end

  teardown do
    # Restore original method
    RssFeed.class_eval do
      alias_method :refresh, :original_refresh
      remove_method :original_refresh
    end

    # Clear the tracking array
    @refreshed_feeds = []
  end

  # Class variable accessor for tracking refreshed feeds
  def self.refreshed_feeds
    @refreshed_feeds ||= []
  end

  test "refreshes feeds that are due for refresh" do
    # Perform the job
    RefreshRssFeedsJob.perform_now

    # Verify the correct feeds were refreshed
    assert_includes self.class.refreshed_feeds, @feed_due_for_refresh.id
    assert_includes self.class.refreshed_feeds, @feed_never_refreshed.id

    assert_not_includes self.class.refreshed_feeds, @feed_not_due.id
    assert_not_includes self.class.refreshed_feeds, @feed_custom_interval.id
  end

  test "updates last_refreshed time when feed is refreshed" do
    old_time = @feed_due_for_refresh.last_refreshed

    # Run the job
    RefreshRssFeedsJob.perform_now
    @feed_due_for_refresh.reload

    # Check that last_refreshed was updated
    assert_not_equal old_time, @feed_due_for_refresh.last_refreshed
    assert_in_delta Time.now, @feed_due_for_refresh.last_refreshed, 1.second
  end

  test "handles feeds with nil refresh_interval" do
    # Create a feed with nil refresh_interval to test the default
    feed_nil_interval = RssFeed.create!(
      name: "Nil interval",
      group: groups(:system_administrators),
      last_refreshed: 2.hours.ago,
      refresh_interval: nil
    )

    # Run the job
    RefreshRssFeedsJob.perform_now

    # Should be refreshed because it uses DEFAULT_REFRESH_INTERVAL (1.hour)
    assert_includes self.class.refreshed_feeds, feed_nil_interval.id
  end
end

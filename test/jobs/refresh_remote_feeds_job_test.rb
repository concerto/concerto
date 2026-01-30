require "test_helper"

class RefreshRemoteFeedsJobTest < ActiveJob::TestCase
  setup do
    RemoteFeed.destroy_all

    @feed_due_for_refresh = RemoteFeed.create!(
      name: "Due for refresh",
      url: "https://example.com/concerto/contents",
      group: groups(:system_administrators)
    )
    @feed_due_for_refresh.last_refreshed = 2.hours.ago
    @feed_due_for_refresh.refresh_interval = 1.hour
    @feed_due_for_refresh.save!

    @feed_not_due = RemoteFeed.create!(
      name: "Not due yet",
      url: "https://example.com/concerto/contents",
      group: groups(:system_administrators)
    )
    @feed_not_due.last_refreshed = 30.minutes.ago
    @feed_not_due.refresh_interval = 1.hour
    @feed_not_due.save!

    @feed_never_refreshed = RemoteFeed.create!(
      name: "Never refreshed",
      url: "https://example.com/concerto/contents",
      group: groups(:system_administrators)
    )

    @refreshed_feeds = []

    RemoteFeed.class_eval do
      alias_method :original_refresh, :refresh

      define_method(:refresh) do
        RefreshRemoteFeedsJobTest.refreshed_feeds << self.id
        self.last_refreshed = Time.now
        self.save!
      end
    end
  end

  teardown do
    RemoteFeed.class_eval do
      alias_method :refresh, :original_refresh
      remove_method :original_refresh
    end

    @refreshed_feeds = []
  end

  def self.refreshed_feeds
    @refreshed_feeds ||= []
  end

  test "refreshes feeds that are due for refresh" do
    RefreshRemoteFeedsJob.perform_now

    assert_includes self.class.refreshed_feeds, @feed_due_for_refresh.id
    assert_includes self.class.refreshed_feeds, @feed_never_refreshed.id
    assert_not_includes self.class.refreshed_feeds, @feed_not_due.id
  end

  test "updates last_refreshed time when feed is refreshed" do
    old_time = @feed_due_for_refresh.last_refreshed

    RefreshRemoteFeedsJob.perform_now
    @feed_due_for_refresh.reload

    assert_not_equal old_time, @feed_due_for_refresh.last_refreshed
    assert_in_delta Time.now, @feed_due_for_refresh.last_refreshed, 1.second
  end

  test "handles feeds with nil refresh_interval" do
    feed_nil_interval = RemoteFeed.create!(
      name: "Nil interval",
      url: "https://example.com/concerto/contents",
      group: groups(:system_administrators),
      last_refreshed: 2.hours.ago,
      refresh_interval: nil
    )

    RefreshRemoteFeedsJob.perform_now

    assert_includes self.class.refreshed_feeds, feed_nil_interval.id
  end
end

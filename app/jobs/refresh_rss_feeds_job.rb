DEFAULT_REFRESH_INTERVAL = 1.hour

class RefreshRssFeedsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    RssFeed.all.each do |feed|
      # Get refresh interval or default.
      interval = feed.refresh_interval ? feed.refresh_interval.seconds : DEFAULT_REFRESH_INTERVAL

      # Check if feed needs refresh
      if feed.last_refreshed.nil? || Time.now >= (feed.last_refreshed + interval)
        Rails.logger.debug "Refreshing #{feed.name}..."
        feed.refresh
      else
        Rails.logger.debug "Skipping refresh of #{feed.name}, next refresh at #{feed.last_refreshed + interval}"
      end
    end
  end
end

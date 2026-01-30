class RefreshRemoteFeedsJob < ApplicationJob
  DEFAULT_REMOTE_REFRESH_INTERVAL = 1.hour

  queue_as :default

  def perform(*args)
    RemoteFeed.find_each do |feed|
      interval = feed.refresh_interval ? feed.refresh_interval.seconds : DEFAULT_REMOTE_REFRESH_INTERVAL

      if feed.last_refreshed.nil? || Time.now >= (feed.last_refreshed + interval)
        Rails.logger.debug "Refreshing #{feed.name}..."
        begin
          feed.refresh
        rescue StandardError => e
          Rails.logger.error "Failed to refresh remote feed #{feed.name}: #{e.class} - #{e.message}"
        end
      else
        Rails.logger.debug "Skipping refresh of #{feed.name}, next refresh at #{feed.last_refreshed + interval}"
      end
    end
  end
end

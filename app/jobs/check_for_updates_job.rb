class CheckForUpdatesJob < ApplicationJob
  queue_as :default

  def perform
    release = UpdateChecker.fetch_from_github
    Rails.cache.write(UpdateChecker::CACHE_KEY, release, expires_in: UpdateChecker::CACHE_TTL)
  end
end

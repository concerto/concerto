class CheckForUpdatesJob < ApplicationJob
  queue_as :default

  def perform
    UpdateChecker.warm_cache
  end
end

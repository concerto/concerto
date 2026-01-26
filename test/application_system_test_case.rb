require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Disable parallel execution for system tests to avoid ActiveStorage race conditions.
  # System tests run a separate server process that can conflict with parallel workers
  # cleaning up shared fixture files in tmp/storage_fixtures.
  parallelize(workers: 1)

  # System tests render full pages that often include video thumbnails
  setup do
    stub_oembed_apis
  end

  if ENV["CAPYBARA_SERVER_PORT"]
    served_by host: "rails-app", port: ENV["CAPYBARA_SERVER_PORT"]

    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ], options: {
      browser: :remote,
      url: "http://#{ENV["SELENIUM_HOST"]}:4444"
    }
  else
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  end

  # Clean out uploaded files.
  def after_teardown
    super
    FileUtils.rm_rf(ActiveStorage::Blob.service.root)
  end
end

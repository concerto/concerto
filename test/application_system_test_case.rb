require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Disable parallel execution for system tests to avoid ActiveStorage race conditions.
  # System tests run a separate server process that can conflict with parallel workers
  # cleaning up shared fixture files in tmp/storage_fixtures.
  parallelize(workers: 1)

  # True when we drive a Selenium container rather than a local browser: the
  # devcontainer, and the legacy-browsers workflow. See docs/legacy_browser_testing.md.
  REMOTE = ENV["CAPYBARA_SERVER_PORT"].present?

  # The grid's browser. The legacy-browsers workflow points us at archived
  # Selenium images holding old Chrome/Firefox builds, so this is no longer
  # always Chrome.
  REMOTE_BROWSER = ENV.fetch("SELENIUM_BROWSER", "chrome").to_sym

  # Selenium 3 grids (the archived images) expose the W3C endpoint under
  # /wd/hub; Selenium 4 serves it at the root. Take the whole URL from the
  # environment so both work.
  REMOTE_URL = ENV.fetch("SELENIUM_URL") { "http://#{ENV["SELENIUM_HOST"]}:4444" }

  if REMOTE
    served_by host: ENV.fetch("CAPYBARA_APP_HOST", "rails-app"), port: ENV["CAPYBARA_SERVER_PORT"]
  end

  # Registers a driver for `browser`, routing through the remote grid whenever
  # one is configured. Subclasses that need a particular browser or window size
  # call this instead of driven_by, so they keep working in both setups.
  def self.drive_with(browser, screen_size: [ 1400, 1400 ])
    options = REMOTE ? { browser: :remote, url: REMOTE_URL } : {}

    driven_by :selenium, using: :"headless_#{browser}", screen_size: screen_size, options: options do |browser_options|
      # Chrome only: keep a console log so tests can assert the player booted
      # without uncaught errors. geckodriver has no equivalent.
      browser_options.add_option("goog:loggingPrefs", { "browser" => "ALL" }) if browser.to_sym == :chrome
    end
  end

  drive_with REMOTE_BROWSER

  # Severe browser-console entries logged so far, newest call draining the
  # buffer. Chrome only; returns [] elsewhere so callers can stay unconditional.
  def severe_browser_logs
    return [] unless page.driver.browser.respond_to?(:logs)

    page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
  rescue Selenium::WebDriver::Error::WebDriverError
    [] # geckodriver and Selenium 4 Chrome both refuse this in some configurations
  end

  # System tests render full pages that often include video thumbnails
  # and the admin header which checks for updates via the GitHub API
  setup do
    # Guarantee a clean, unauthenticated session at the start of every system
    # test. Devise only resets Warden in teardown, and we otherwise rely on
    # Capybara clearing the session cookie between tests -- which is unreliable
    # with the remote Selenium driver used in CI. Resetting here neutralizes any
    # authenticated session leaking in from a prior test, which otherwise causes
    # anonymous tests to render content scoped to the leaked user. See #1834.
    Warden.test_reset!
    Capybara.reset_sessions!

    stub_oembed_apis
    stub_github_releases_api
  end

  # Clean out uploaded files.
  def after_teardown
    super
    FileUtils.rm_rf(ActiveStorage::Blob.service.root)
  end
end

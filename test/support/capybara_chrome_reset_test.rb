require "test_helper"
require_relative "capybara_chrome_reset"

class CapybaraChromeResetTest < ActiveSupport::TestCase
  class FakeBridge
    attr_reader :http_calls

    def initialize(history_entries: [], fail_commands: {})
      @history_entries = history_entries
      @fail_commands = fail_commands
      @http_calls = []
    end

    def session_id
      "session-123"
    end

    def log(_type)
      []
    end

    def commands(_name)
      true
    end

    def http
      owner = self
      Object.new.tap do |client|
        client.define_singleton_method(:call) { |verb, path, payload| owner.record_http_call(verb, path, payload) }
      end
    end

    def record_http_call(verb, path, payload)
      @http_calls << [ verb, path, payload ]
      cmd = payload[:cmd]
      if (error = @fail_commands[cmd])
        raise error
      end

      value = cmd == "Page.getNavigationHistory" ? { "entries" => @history_entries } : {}
      { "value" => value }
    end
  end

  class FakeBrowser
    attr_reader :cdp_calls, :managed_cookie_deletes, :navigated_urls

    def initialize(history_entries: [], fail_commands: {}, chromedriver_version: "158.0.8127.18")
      @history_entries = history_entries
      @fail_commands = fail_commands
      @chromedriver_version = chromedriver_version
      @cdp_calls = []
      @managed_cookie_deletes = 0
      @navigated_urls = []
      @bridge = FakeBridge.new(history_entries: history_entries, fail_commands: fail_commands)
    end

    def execute_cdp(cmd, **params)
      @cdp_calls << [ cmd, params ]
      if (error = @fail_commands[cmd])
        raise error
      end

      case cmd
      when "Page.getNavigationHistory"
        { "entries" => @history_entries }
      else
        {}
      end
    end

    def capabilities
      { "chrome" => { "chromedriverVersion" => @chromedriver_version } }
    end

    def window_handles
      [ "window-1" ]
    end

    def switch_to
      @switch_to ||= Struct.new(:windows) do
        def window(handle)
          windows << handle
        end
      end.new([])
    end

    def navigate
      urls = @navigated_urls
      Struct.new(:urls) do
        def to(url)
          urls << url
        end
      end.new(urls)
    end

    def manage
      owner = self
      Object.new.tap do |manager|
        manager.define_singleton_method(:delete_all_cookies) { owner.record_managed_cookie_delete }
      end
    end

    def record_managed_cookie_delete
      @managed_cookie_deletes += 1
    end

    private

    attr_reader :bridge
  end

  class FakeRemoteBrowser < FakeBrowser
    undef_method :execute_cdp

    def bridge_http_calls
      @bridge.http_calls
    end
  end

  def build_chrome_driver(browser, **options)
    driver = Capybara::Selenium::Driver.new(nil, browser: :chrome, **options)
    driver.instance_variable_set(:@browser, browser)
    driver.extend(Capybara::Selenium::Driver::ChromeDriver)
    driver.define_singleton_method(:wait_for_empty_page) { |_timer| nil }
    driver
  end

  test "reset! clears cookies and per-origin local storage without sending wildcard origin" do
    browser = FakeBrowser.new(
      history_entries: [
        { "url" => "about:blank" },
        { "url" => "http://127.0.0.1:45678/screens" },
        { "url" => "http://127.0.0.1:45678/feeds" },
        { "url" => "https://example.com:443/path" },
        { "url" => "http://[::1]:3000/player" },
        { "url" => "data:text/html,<p>hi</p>" },
        { "url" => "chrome-error://chromewebdata/" },
        { "url" => "http://[::1" },
        { "url" => nil }
      ]
    )
    driver = build_chrome_driver(browser)

    driver.reset!

    assert_equal [ "about:blank" ], browser.navigated_urls
    assert_equal [
      [ "Network.clearBrowserCookies", {} ],
      [ "Page.getNavigationHistory", {} ],
      [ "Storage.clearDataForOrigin", { origin: "http://127.0.0.1:45678", storageTypes: "local_storage" } ],
      [ "Storage.clearDataForOrigin", { origin: "https://example.com", storageTypes: "local_storage" } ],
      [ "Storage.clearDataForOrigin", { origin: "http://[::1]:3000", storageTypes: "local_storage" } ]
    ], browser.cdp_calls
  end

  test "reset! works with remote Selenium drivers that dispatch CDP over HTTP" do
    browser = FakeRemoteBrowser.new(
      chromedriver_version: "79.0.3945.36",
      history_entries: [
        { "url" => "http://127.0.0.1:45678/frontend/1" },
        { "url" => "about:blank" }
      ]
    )
    driver = build_chrome_driver(browser)

    driver.reset!

    assert_equal [
      [ :post, "session/session-123/goog/cdp/execute", { cmd: "Network.clearBrowserCookies", params: {} } ],
      [ :post, "session/session-123/goog/cdp/execute", { cmd: "Page.getNavigationHistory", params: {} } ],
      [ :post, "session/session-123/goog/cdp/execute", {
        cmd: "Storage.clearDataForOrigin",
        params: { origin: "http://127.0.0.1:45678", storageTypes: "local_storage" }
      } ]
    ], browser.bridge_http_calls
  end

  test "reset! skips local storage clearing when clear_local_storage is false" do
    browser = FakeBrowser.new(
      history_entries: [ { "url" => "http://127.0.0.1:45678/screens" } ]
    )
    driver = build_chrome_driver(browser, clear_local_storage: false, clear_session_storage: false)

    driver.reset!

    assert_equal [ [ "Network.clearBrowserCookies", {} ] ], browser.cdp_calls
  end

  test "reset! falls back to WebDriver cookie clearing and tolerates unsupported history CDP" do
    browser = FakeBrowser.new(
      fail_commands: {
        "Network.clearBrowserCookies" => Selenium::WebDriver::Error::WebDriverError.new("unsupported"),
        "Page.getNavigationHistory" => Selenium::WebDriver::Error::WebDriverError.new("unsupported")
      }
    )
    driver = build_chrome_driver(browser)

    driver.reset!

    assert_equal 1, browser.managed_cookie_deletes
    assert_equal [
      [ "Network.clearBrowserCookies", {} ],
      [ "Page.getNavigationHistory", {} ]
    ], browser.cdp_calls
  end

  test "non-wildcard Storage.clearDataForOrigin calls pass through unchanged" do
    browser = FakeBrowser.new
    driver = build_chrome_driver(browser)

    driver.send(:execute_cdp, "Storage.clearDataForOrigin", origin: "http://127.0.0.1:45678", storageTypes: "cookies")

    assert_equal [
      [ "Storage.clearDataForOrigin", { origin: "http://127.0.0.1:45678", storageTypes: "cookies" } ]
    ], browser.cdp_calls
  end
end

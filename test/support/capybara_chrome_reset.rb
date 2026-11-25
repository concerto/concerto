require "capybara/selenium/driver"

# Chrome 158 tightened DevTools origin validation on Storage.clearDataForOrigin
# and rejects Capybara 3.40.0's wildcard `origin: "*"` with
# `Selenium::WebDriver::Error::InvalidArgumentError: invalid argument: * is not a valid URL`.
#
# Intercept that wildcard CDP call and instead:
# - clear all cookies via `delete_all_cookies` (`Network.clearBrowserCookies`,
#   with Capybara's fallback to WebDriver `manage.delete_all_cookies`), and
# - when `local_storage` is requested, clear DOM storage for each http(s) origin
#   recorded in the current tab's navigation history (`Page.getNavigationHistory`).
#
# Once an upstream Capybara release stops sending `origin: "*"`, this prepend
# becomes a no-op pass-through and can be removed.
# See https://github.com/teamcapybara/capybara/issues/2865
module CapybaraChromeReset
  private

  def execute_cdp(cmd, params = {})
    return super unless cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"

    delete_all_cookies
    return unless params[:storageTypes].to_s.split(",").include?("local_storage")

    visited_origins.each do |origin|
      super(cmd, origin: origin, storageTypes: "local_storage")
    end
  end

  def visited_origins
    entries = execute_cdp("Page.getNavigationHistory")&.fetch("entries", nil) || []
    entries.filter_map { |entry| origin_of(entry["url"]) }.uniq
  rescue *cdp_unsupported_errors
    []
  end

  def origin_of(url)
    uri = URI.parse(url.to_s)
    scheme = uri.scheme&.downcase
    return unless %w[http https].include?(scheme) && !uri.host.to_s.empty?

    port = ":#{uri.port}" unless uri.port.nil? || uri.port == uri.default_port
    "#{scheme}://#{uri.host}#{port}"
  rescue URI::InvalidURIError
    nil
  end
end

unless Capybara::Selenium::Driver::ChromeDriver.ancestors.include?(CapybaraChromeReset)
  Capybara::Selenium::Driver::ChromeDriver.prepend(CapybaraChromeReset)
end

require "net/http"
require "json"

class UpdateChecker
  GITHUB_REPO = "concerto/concerto"
  CACHE_KEY = "update_checker/latest_release"
  CACHE_TTL = 24.hours
  HTTP_OPEN_TIMEOUT = 5
  HTTP_READ_TIMEOUT = 10

  def self.latest_release
    return nil if Rails.env.test?
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) { fetch_from_github }
  end

  def self.update_available?
    release = latest_release
    return false unless release

    Gem::Version.new(release[:tag]) > Gem::Version.new(APP_VERSION)
  rescue ArgumentError
    false
  end

  def self.fetch_from_github
    uri = URI("https://api.github.com/repos/#{GITHUB_REPO}/releases/latest")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = HTTP_OPEN_TIMEOUT
    http.read_timeout = HTTP_READ_TIMEOUT

    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/vnd.github+json"
    request["X-GitHub-Api-Version"] = "2022-11-28"
    request["User-Agent"] = "Concerto/#{APP_VERSION}"

    response = http.request(request)
    return nil unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    { tag: body["tag_name"].delete_prefix("v"), url: body["html_url"] }
  rescue StandardError => e
    Rails.logger.error "UpdateChecker failed: #{e.class} - #{e.message}"
    nil
  end
end

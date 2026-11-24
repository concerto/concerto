require "net/http"
require "uri"

class RssFeed < Feed
  HTTP_OPEN_TIMEOUT = 5 # seconds to wait for connection
  HTTP_READ_TIMEOUT = 30 # seconds to wait for response
  MAX_REDIRECTS = 5
  MAX_RESPONSE_SIZE = 5.megabytes

  class FetchError < StandardError; end

  store_accessor :config, [ :url, :last_refreshed, :refresh_interval, :formatter ]

  # RSS feed content is auto-approved since it's system-generated
  def auto_approves_submissions?
    true
  end

  validates :url, presence: true
  validate :url_must_be_http

  # Destroy all associated content when an RSS feed is deleted
  before_destroy :destroy_associated_content, prepend: true

  def last_refreshed
    DateTime.parse(super) if super
  end

  def refresh_interval
    super.to_i if super
  end

  def headlines? = formatter == "headlines"
  def details? = formatter == "details"
  def ticker? = formatter == "ticker"
  def self.formatters
    { headlines: "headlines", details: "details", ticker: "ticker" }
  end

  def render_mode
    (ticker? ? RichText.render_as[:plaintext] : RichText.render_as[:html])
  end

  def searchable_data
    { name: name, body: [ description, indexable_url ].compact_blank.join(" ") }
  end

  def refresh
    items = new_items
    system_user = User.find_by(is_system_user: true)
    existing_content = managed_content(system_user).order(:id).to_a

    expired_time = Time.now

    existing_content.each.with_index do |item_content, index|
      # First, update all the existing system-owned RichText content.
      if items.length > index
        item_content.render_as = render_mode
        item_content.text = items[index]
        item_content.name = "#{name} (#{index + 1})"
        item_content.start_time = nil
        item_content.end_time = nil
      else
        # Then, expire any un-updated content.
        item_content.text = ""
        item_content.name = "#{name} (unused)"
        item_content.end_time = expired_time
      end
      item_content.save
    end

    # If there are any new items left, create new RichText content.
    offset = items.length - existing_content.length
    if offset > 0
      items[existing_content.length..].each.with_index do |item, index|
        content << RichText.new(
          render_as: render_mode,
          name: "#{name} (#{existing_content.length + index + 1})",
          text: item,
          user: system_user
        )
      end
    end

    # Update the last refreshed time.
    self.last_refreshed = Time.now
    self.save
  end

  def new_items
    xml = fetch_feed_xml
    doc = Nokogiri::XML(xml) { |config| config.nonet }

    title = doc.xpath("/rss/channel/title").text
    items = doc.xpath("//item").map do |item|
      { title: item.xpath("title").text,
        description: item.xpath("description").text }
    end

    contents = []

    if details?
      items.each do |item|
        description = ActionController::Base.helpers.sanitize(item[:description])
        contents << "<h1>#{CGI.escapeHTML(item[:title])}</h1><p>#{description}</p>"
      end
    elsif ticker?
      items.each do |item|
        contents << CGI.unescapeHTML(ActionController::Base.helpers.strip_tags(item[:title])).squish
      end
    else # headlines
      items.each_slice(5) do |slice|
        item_titles = slice.map { |i| CGI.escapeHTML(i[:title]) }
        contents << "<h1>#{CGI.escapeHTML(title)}</h1><h2>#{item_titles.join("</h2><h2>")}</h2>"
      end
    end

    contents
  end

  # Deletes all unused system-generated content for this RSS feed
  def cleanup_unused_content
    managed_content.unused.destroy_all
  end

  private

  # Only allow absolute http(s) URLs. Private/internal hostnames and IPs are
  # intentionally permitted for intranet deployments (see #2002).
  def url_must_be_http
    return if url.blank?

    uri = URI.parse(url)
    unless uri.is_a?(URI::HTTP) && uri.host.present?
      errors.add(:url, "must be a valid http or https URL")
    end
  rescue URI::InvalidURIError
    errors.add(:url, "is not a valid URL")
  end

  def parse_http_uri(raw_url)
    return nil if raw_url.blank?

    uri = URI.parse(raw_url)
    uri.is_a?(URI::HTTP) && uri.host.present? ? uri : nil
  rescue URI::InvalidURIError
    nil
  end

  def fetch_feed_xml(target_url = url, redirects_remaining: MAX_REDIRECTS)
    uri = parse_http_uri(target_url)
    raise FetchError, "Invalid RSS feed URL" unless uri

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = HTTP_OPEN_TIMEOUT
    http.read_timeout = HTTP_READ_TIMEOUT

    redirect_location = nil
    body = String.new(encoding: Encoding::BINARY)

    http.start do |conn|
      request = Net::HTTP::Get.new(uri.request_uri)
      conn.request(request) do |response|
        if response.is_a?(Net::HTTPRedirection)
          raise FetchError, "Too many redirects fetching RSS feed" if redirects_remaining <= 0

          location = response["location"]
          raise FetchError, "Redirect missing Location header" if location.blank?

          begin
            redirect_location = URI.join(uri, location).to_s
          rescue URI::InvalidURIError
            raise FetchError, "Invalid redirect URL"
          end
        elsif response.is_a?(Net::HTTPSuccess)
          content_length = response["content-length"]&.to_i
          if content_length && content_length > MAX_RESPONSE_SIZE
            raise FetchError, "RSS feed response exceeds maximum size (#{MAX_RESPONSE_SIZE} bytes)"
          end

          response.read_body do |chunk|
            body << chunk
            if body.bytesize > MAX_RESPONSE_SIZE
              raise FetchError, "RSS feed response exceeds maximum size (#{MAX_RESPONSE_SIZE} bytes)"
            end
          end
        else
          raise FetchError, "HTTP #{response.code} #{response.message}".strip
        end
      end
    end

    if redirect_location
      fetch_feed_xml(redirect_location, redirects_remaining: redirects_remaining - 1)
    else
      body
    end
  end

  def managed_content(system_user = User.find_by(is_system_user: true))
    return content.none unless system_user

    content.where(type: "RichText", user_id: system_user.id)
  end

  def destroy_associated_content
    # Capture content IDs before Rails destroys the submission join.
    content_ids = content.pluck(:id)

    # Directly destroy the content records, not just the association.
    Content.where(id: content_ids).destroy_all
  end
end

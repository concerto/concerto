require "net/http"
require "digest"
require "tempfile"
require "uri"

class RemoteFeed < Feed
  # HTTP timeout and redirect settings for remote requests
  HTTP_OPEN_TIMEOUT = 5 # seconds to wait for connection
  HTTP_READ_TIMEOUT = 30 # seconds to wait for response
  MAX_REDIRECTS = 5

  # Maximum response sizes to prevent DoS attacks
  MAX_FEED_SIZE = 5.megabytes
  MAX_IMAGE_SIZE = 10.megabytes

  DownloadedImage = Data.define(:tempfile, :filename, :content_type)
  private_constant :DownloadedImage

  class ResponseTooLargeError < StandardError; end
  private_constant :ResponseTooLargeError

  store_accessor :config, [ :url, :last_refreshed, :refresh_interval ]

  # Remote feed content is auto-approved since it's system-generated
  def auto_approves_submissions?
    true
  end

  validates :url, presence: true
  validate :url_must_be_http

  before_destroy :destroy_associated_content, prepend: true

  # Use RemoteFeedPolicy for authorization (overrides Feed's policy_class)
  def self.policy_class
    RemoteFeedPolicy
  end

  def last_refreshed
    DateTime.parse(super) if super
  end

  def refresh_interval
    super.to_i if super
  end

  def searchable_data
    { name: name, body: [ description, indexable_url ].compact_blank.join(" ") }
  end

  def refresh
    feed_body = fetch_feed_body
    return unless feed_body

    items = JSON.parse(feed_body)
    unless items.is_a?(Array)
      Rails.logger.error "Remote feed #{name} did not return an array"
      return
    end

    system_user = User.find_by(is_system_user: true)
    items = deduplicate_item_names(items)

    # Pre-download any new or changed Graphic images outside the DB transaction
    # so slow HTTP transfers never hold a SQLite write lock.
    existing_snapshot = index_managed_content(system_user)
    staged_images = stage_graphic_images(items, existing_snapshot)

    begin
      ActiveRecord::Base.transaction do
        existing_by_key = index_managed_content(system_user)
        new_keys = Set.new

        items.each do |item|
          key = [ item["type"], item["name"] ]
          new_keys.add(key)
          digest = compute_digest(item)

          if (existing = existing_by_key[key])
            # Update in place if anything changed, preserving the content ID
            if existing.config&.dig("remote_digest") != digest
              update_content(existing, item, digest, staged_images[key])
            end
          else
            content_obj = build_content(item, system_user, digest, staged_images[key])
            content_obj.save!
            submissions.create!(content: content_obj) unless submissions.exists?(content: content_obj)
          end
        end

        # Remove managed content whose [type, name] is no longer in the feed
        existing_by_key.each do |key, c|
          c.destroy unless new_keys.include?(key)
        end

        self.last_refreshed = Time.now
        self.save
      end
    ensure
      staged_images.each_value { |img| img&.tempfile&.close! }
    end
  rescue URI::InvalidURIError => e
    Rails.logger.error "Invalid URL for remote feed #{name}: #{e.message}"
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.error "Timeout fetching remote feed #{name}: #{e.message}"
  rescue JSON::ParserError => e
    Rails.logger.error "Invalid JSON from remote feed #{name}: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Error refreshing remote feed #{name}: #{e.class} - #{e.message}"
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

  def fetch_feed_body(target_url = url, redirects_remaining: MAX_REDIRECTS)
    uri = parse_http_uri(target_url)
    unless uri
      Rails.logger.error "Invalid URL for remote feed #{name}: #{target_url}"
      return nil
    end

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
          if redirects_remaining <= 0
            Rails.logger.error "Too many redirects fetching remote feed #{name}"
            return nil
          end

          location = response["location"]
          if location.blank?
            Rails.logger.error "Redirect missing Location header fetching remote feed #{name}"
            return nil
          end

          redirect_location = URI.join(uri, location).to_s
        elsif response.is_a?(Net::HTTPSuccess)
          content_length = response["content-length"]&.to_i
          if content_length && content_length > MAX_FEED_SIZE
            Rails.logger.error "Remote feed #{name} response too large: #{content_length} bytes"
            return nil
          end

          response.read_body do |chunk|
            body << chunk
            if body.bytesize > MAX_FEED_SIZE
              Rails.logger.error "Remote feed #{name} response exceeded #{MAX_FEED_SIZE} bytes"
              raise ResponseTooLargeError
            end
          end
        else
          Rails.logger.error "Failed to fetch remote feed #{name}: HTTP #{response.code}"
          return nil
        end
      end
    end

    if redirect_location
      fetch_feed_body(redirect_location, redirects_remaining: redirects_remaining - 1)
    else
      body
    end
  rescue ResponseTooLargeError
    nil
  end

  def index_managed_content(system_user)
    return {} unless system_user

    existing_by_key = {}
    content.reload.each do |c|
      next unless managed_content?(c, system_user)

      existing_by_key[[ c.type, c.name ]] ||= c
    end
    existing_by_key
  end

  def managed_content?(record, system_user)
    record.user_id == system_user.id &&
      record.config.is_a?(Hash) &&
      record.config.key?("remote_digest")
  end

  def stage_graphic_images(items, existing_by_key)
    staged = {}

    items.each do |item|
      next unless item["type"] == "Graphic"

      key = [ item["type"], item["name"] ]
      existing = existing_by_key[key]
      digest = compute_digest(item)

      needs_download = if existing.nil?
        true
      elsif existing.config&.dig("remote_digest") != digest
        existing.config&.dig("image_url") != item["url"]
      else
        false
      end

      staged[key] = download_image(item["url"]) if needs_download
    end

    staged
  end

  def compute_digest(item)
    significant = {
      type: item["type"],
      name: item["name"],
      text: item["text"],
      url: item["url"],
      render_as: item["render_as"],
      duration: item["duration"],
      start_time: item["start_time"],
      end_time: item["end_time"]
    }
    Digest::SHA256.hexdigest(significant.to_json)
  end

  def build_content(item, system_user, digest, staged_image = nil)
    common_attrs = {
      name: item["name"],
      duration: item["duration"],
      start_time: item["start_time"] ? Time.parse(item["start_time"]) : nil,
      end_time: item["end_time"] ? Time.parse(item["end_time"]) : nil,
      user: system_user
    }

    case item["type"]
    when "RichText"
      RichText.new(
        **common_attrs,
        text: item["text"],
        render_as: item["render_as"],
        config: { remote_digest: digest, render_as: item["render_as"] }
      )
    when "Graphic"
      graphic_config = if staged_image
        { remote_digest: digest, image_url: item["url"] }
      else
        { remote_digest: nil, image_url: nil }
      end
      graphic = Graphic.new(**common_attrs, config: graphic_config)
      attach_staged_image(graphic, staged_image) if staged_image
      graphic
    when "Video"
      Video.new(
        **common_attrs,
        config: { remote_digest: digest, url: item["url"] }
      )
    else
      raise "Unknown content type: #{item["type"]}"
    end
  end

  def deduplicate_item_names(items)
    items.group_by { |item| [ item["type"], item["name"] ] }.flat_map do |_, group|
      if group.size > 1
        group.map.with_index(1) { |item, i| item.merge("name" => "#{item["name"]} (#{i})") }
      else
        group
      end
    end
  end

  def update_content(existing, item, digest, staged_image = nil)
    common_attrs = {
      name: item["name"],
      duration: item["duration"],
      start_time: item["start_time"] ? Time.parse(item["start_time"]) : nil,
      end_time: item["end_time"] ? Time.parse(item["end_time"]) : nil
    }

    case item["type"]
    when "RichText"
      existing.update!(
        **common_attrs,
        text: item["text"],
        render_as: item["render_as"],
        config: existing.config.merge("remote_digest" => digest, "render_as" => item["render_as"])
      )
    when "Graphic"
      old_image_url = existing.config&.dig("image_url")
      if old_image_url != item["url"]
        if staged_image
          existing.update!(
            **common_attrs,
            image: {
              io: staged_image.tempfile,
              filename: staged_image.filename,
              content_type: staged_image.content_type
            },
            config: existing.config.merge("remote_digest" => digest, "image_url" => item["url"])
          )
        else
          # Keep the existing image and previous image_url/remote_digest so a
          # transient download failure never destroys working signage and the
          # next refresh retries fetching the new image.
          existing.update!(**common_attrs)
        end
      else
        existing.update!(
          **common_attrs,
          config: existing.config.merge("remote_digest" => digest)
        )
      end
    when "Video"
      existing.update!(
        **common_attrs,
        config: existing.config.merge("remote_digest" => digest, "url" => item["url"])
      )
    else
      raise "Unknown content type: #{item["type"]}"
    end
  end

  def attach_staged_image(graphic, staged_image)
    graphic.image.attach(
      io: staged_image.tempfile,
      filename: staged_image.filename,
      content_type: staged_image.content_type
    )
  end

  def parse_content_type(raw_header)
    raw_header.to_s.split(";").first&.strip&.downcase.presence || "image/png"
  end

  def download_image(image_url, redirects_remaining: MAX_REDIRECTS)
    uri = parse_http_uri(image_url)
    unless uri
      Rails.logger.error "Invalid image URL for remote feed #{name}: #{image_url}"
      return nil
    end

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = HTTP_OPEN_TIMEOUT
    http.read_timeout = HTTP_READ_TIMEOUT

    redirect_location = nil
    downloaded = nil

    http.start do |conn|
      request = Net::HTTP::Get.new(uri.request_uri)
      conn.request(request) do |response|
        if response.is_a?(Net::HTTPRedirection)
          if redirects_remaining <= 0
            Rails.logger.error "Too many redirects downloading image from #{image_url}"
            return nil
          end

          location = response["location"]
          if location.blank?
            Rails.logger.error "Redirect missing Location header downloading image from #{image_url}"
            return nil
          end

          redirect_location = URI.join(uri, location).to_s
        elsif response.is_a?(Net::HTTPSuccess)
          content_length = response["content-length"]&.to_i
          if content_length && content_length > MAX_IMAGE_SIZE
            Rails.logger.error "Image too large from #{image_url}: #{content_length} bytes"
            return nil
          end

          content_type = parse_content_type(response["content-type"])
          extension = Rack::Mime::MIME_TYPES.invert[content_type] || ".png"
          path_basename = File.basename(uri.path.to_s)
          filename = (path_basename.present? && path_basename != "/" && path_basename != ".") ? path_basename : "image#{extension}"

          tempfile = Tempfile.new([ "remote_feed_image", extension ], binmode: true)
          bytes_written = 0
          begin
            response.read_body do |chunk|
              bytes_written += chunk.bytesize
              if bytes_written > MAX_IMAGE_SIZE
                Rails.logger.error "Image too large from #{image_url}: exceeded #{MAX_IMAGE_SIZE} bytes"
                raise ResponseTooLargeError
              end
              tempfile.write(chunk)
            end
            tempfile.rewind
            downloaded = DownloadedImage.new(tempfile: tempfile, filename: filename, content_type: content_type)
          rescue StandardError
            tempfile.close!
            raise
          end
        else
          Rails.logger.error "Failed to download image from #{image_url}: HTTP #{response.code}"
          return nil
        end
      end
    end

    if redirect_location
      download_image(redirect_location, redirects_remaining: redirects_remaining - 1)
    else
      downloaded
    end
  rescue ResponseTooLargeError
    nil
  rescue URI::InvalidURIError, Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, OpenSSL::SSL::SSLError => e
    Rails.logger.error "Error downloading image from #{image_url}: #{e.class} - #{e.message}"
    nil
  end

  def destroy_associated_content
    content_ids = content.pluck(:id)
    Content.where(id: content_ids).destroy_all
  end
end

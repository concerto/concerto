require "net/http"
require "digest"

class RemoteFeed < Feed
    # HTTP timeout settings for remote requests
    HTTP_OPEN_TIMEOUT = 5 # seconds to wait for connection
    HTTP_READ_TIMEOUT = 30 # seconds to wait for response

    # Maximum image file size to prevent DoS attacks
    MAX_IMAGE_SIZE = 10.megabytes

    store_accessor :config, [ :url, :last_refreshed, :refresh_interval ]

    validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }

    before_destroy :destroy_associated_content, prepend: true

    def last_refreshed
      DateTime.parse(super) if super
    end

    def refresh_interval
      super.to_i if super
    end

    def refresh
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = HTTP_OPEN_TIMEOUT
      http.read_timeout = HTTP_READ_TIMEOUT

      response = http.get(uri.request_uri)
      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error "Failed to fetch remote feed #{name}: HTTP #{response.code}"
        return
      end

      items = JSON.parse(response.body)
      unless items.is_a?(Array)
        Rails.logger.error "Remote feed #{name} did not return an array"
        return
      end

      system_user = User.find_by(is_system_user: true)

      ActiveRecord::Base.transaction do
        # Compute digest for each incoming item
        new_digests = {}
        items.each do |item|
          digest = compute_digest(item)
          new_digests[digest] = item
        end

        # Index existing content by stored digest
        existing_by_digest = {}
        content.reload.each do |c|
          d = c.config&.dig("remote_digest")
          existing_by_digest[d] = c if d
        end

        # Delete items whose digest is absent from new response
        existing_by_digest.each do |digest, c|
          unless new_digests.key?(digest)
            c.destroy
          end
        end

        # Create new items for unmatched digests
        new_digests.each do |digest, item|
          next if existing_by_digest.key?(digest)

          content_obj = build_content(item, system_user, digest)
          content_obj.save!
          submissions.create!(content: content_obj) unless submissions.exists?(content: content_obj)
        end

        self.last_refreshed = Time.now
        self.save
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

    def build_content(item, system_user, digest)
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
        graphic = Graphic.new(**common_attrs, config: { remote_digest: digest })
        download_and_attach_image(graphic, item["url"])
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

    def download_and_attach_image(graphic, image_url)
      uri = URI.parse(image_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = HTTP_OPEN_TIMEOUT
      http.read_timeout = HTTP_READ_TIMEOUT

      response = http.get(uri.request_uri)
      if response.is_a?(Net::HTTPSuccess)
        if response.body.bytesize > MAX_IMAGE_SIZE
          Rails.logger.error "Image too large for #{graphic.name}: #{response.body.bytesize} bytes"
          return
        end

        content_type = response["content-type"] || "image/png"
        extension = Rack::Mime::MIME_TYPES.invert[content_type] || ".png"
        filename = File.basename(uri.path).presence || "image#{extension}"
        graphic.image.attach(
          io: StringIO.new(response.body),
          filename: filename,
          content_type: content_type
        )
      else
        Rails.logger.error "Failed to download image from #{image_url}: HTTP #{response.code}"
      end
    rescue URI::InvalidURIError, Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.error "Error downloading image from #{image_url}: #{e.message}"
    end

    def destroy_associated_content
      content_ids = content.pluck(:id)
      Content.where(id: content_ids).destroy_all
    end
end

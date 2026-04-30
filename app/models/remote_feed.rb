require "net/http"
require "digest"

class RemoteFeed < Feed
    # HTTP timeout settings for remote requests
    HTTP_OPEN_TIMEOUT = 5 # seconds to wait for connection
    HTTP_READ_TIMEOUT = 30 # seconds to wait for response

    # Maximum image file size to prevent DoS attacks
    MAX_IMAGE_SIZE = 10.megabytes

    store_accessor :config, [ :url, :last_refreshed, :refresh_interval ]

    # Remote feed content is auto-approved since it's system-generated
    def auto_approves_submissions?
      true
    end

    validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }

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
        items = deduplicate_item_names(items)

        # Index existing content by [type, name] — stable identity across data changes
        existing_by_key = {}
        content.reload.each do |c|
          existing_by_key[[ c.type, c.name ]] ||= c
        end

        new_keys = Set.new

        items.each do |item|
          key = [ item["type"], item["name"] ]
          new_keys.add(key)
          digest = compute_digest(item)

          if (existing = existing_by_key[key])
            # Update in place if anything changed, preserving the content ID
            update_content(existing, item, digest) if existing.config&.dig("remote_digest") != digest
          else
            content_obj = build_content(item, system_user, digest)
            content_obj.save!
            submissions.create!(content: content_obj) unless submissions.exists?(content: content_obj)
          end
        end

        # Remove content whose [type, name] is no longer in the feed
        existing_by_key.each do |key, c|
          c.destroy unless new_keys.include?(key)
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
        graphic = Graphic.new(**common_attrs, config: { remote_digest: digest, image_url: item["url"] })
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

    def deduplicate_item_names(items)
      items.group_by { |item| [ item["type"], item["name"] ] }.flat_map do |_, group|
        if group.size > 1
          group.map.with_index(1) { |item, i| item.merge("name" => "#{item["name"]} (#{i})") }
        else
          group
        end
      end
    end

    def update_content(existing, item, digest)
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
        existing.update!(**common_attrs, config: existing.config.merge("remote_digest" => digest, "image_url" => item["url"]))
        if old_image_url != item["url"]
          existing.image.purge if existing.image.attached?
          download_and_attach_image(existing, item["url"])
          existing.save!
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

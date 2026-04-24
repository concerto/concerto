require "net/http"
require "cgi"

class Video < Content
  store_accessor :config, :url, :aspect_ratio

  # Permitted values for the user-facing aspect ratio override, with the
  # labels shown in the form. nil / "auto" means "use the provider default"
  # (with /shorts/ URL detection for YouTube and dynamic correction for Vimeo
  # on the frontend).
  ASPECT_RATIO_OPTIONS = {
    "auto" => "Auto (detect from source)",
    "16:9" => "16:9 (widescreen)",
    "9:16" => "9:16 (vertical)",
    "4:3" => "4:3 (standard)",
    "1:1" => "1:1 (square)"
  }.freeze
  ASPECT_RATIOS = ASPECT_RATIO_OPTIONS.keys.freeze

  validates :aspect_ratio, inclusion: { in: ASPECT_RATIOS }, allow_blank: true

  def as_json(options = {})
    super(options).merge({
      video_id: video_id,
      video_source: video_source,
      aspect_ratio: effective_aspect_ratio,
      aspect_ratio_auto: aspect_ratio.blank? || aspect_ratio == "auto"
    })
  end

  # Resolves the CSS-ready aspect ratio string (e.g. "16/9") the frontend should
  # use as the initial rendering ratio. Falls back to provider defaults when the
  # user has not set an explicit override.
  def effective_aspect_ratio
    ratio = aspect_ratio
    return ratio.tr(":", "/") if ratio.present? && ratio != "auto"

    case video_source
    when "youtube" then url.to_s.include?("/shorts/") ? "9/16" : "16/9"
    when "tiktok" then "9/16"
    else "16/9"
    end
  end

  # For now, videos should only be rendered in positions that are roughly
  # somewhere in the [4:3 - 16:9] range, with a large buffer.
  def should_render_in?(position)
    # I don't really know what these numbers should be, there
    # is room for tuning.
    (0.25 < position.aspect_ratio && position.aspect_ratio <= 1)
  end

  def video_id
    if url.present?
      if video_source == "youtube"
        match = url.match(/(?:youtube\.com\/(?:shorts\/|[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/i)
        match[1] if match
      elsif video_source == "vimeo"
        match = url.match(/vimeo\.com\/(\d+)/)
        match[1] if match
      elsif video_source == "tiktok"
        # Extract video ID from oEmbed data for better reliability and short URL support
        data = tiktok_oembed_data
        if data && data["html"]
          match = data["html"].match(/data-video-id="(\d+)"/)
          match[1] if match
        end
      end
    end
  end

  def video_source
    if url.present?
      host = URI(url).host
      yt_hosts = [
        "youtube.com",
        "www.youtube.com",
        "youtu.be"
      ]
      tiktok_hosts = [
        "tiktok.com",
        "www.tiktok.com",
        "vm.tiktok.com",
        "vt.tiktok.com"
      ]
      if yt_hosts.include?(host)
        "youtube"
      elsif [ "vimeo.com" ].include?(host)
        "vimeo"
      elsif tiktok_hosts.include?(host)
        "tiktok"
      end
    end
  end

  def thumbnail_url
    if video_source == "youtube"
      "https://img.youtube.com/vi/#{video_id}/mqdefault.jpg"
    elsif video_source == "vimeo"
      data = vimeo_oembed_data
      data&.dig("thumbnail_url") || ""
    elsif video_source == "tiktok"
      data = tiktok_oembed_data
      data&.dig("thumbnail_url") || ""
    else
      ""
    end
  end

  private

  # Memoized helper to fetch Vimeo oEmbed data once per request
  def vimeo_oembed_data
    return @vimeo_oembed_data if instance_variable_defined?(:@vimeo_oembed_data)

    @vimeo_oembed_data = begin
      uri = URI("https://vimeo.com/api/oembed.json?url=#{CGI.escape(url)}")
      response = Net::HTTP.get(uri)
      JSON.parse(response)
    rescue StandardError => e
      Rails.logger.error "Error fetching Vimeo oEmbed data: #{e.message}"
      nil
    end
  end

  # Memoized helper to fetch TikTok oEmbed data once per request
  # This supports all TikTok URL formats including short links
  def tiktok_oembed_data
    return @tiktok_oembed_data if instance_variable_defined?(:@tiktok_oembed_data)

    @tiktok_oembed_data = begin
      uri = URI("https://www.tiktok.com/oembed?url=#{CGI.escape(url)}")
      response = Net::HTTP.get(uri)
      JSON.parse(response)
    rescue StandardError => e
      Rails.logger.error "Error fetching TikTok oEmbed data: #{e.message}"
      nil
    end
  end
end

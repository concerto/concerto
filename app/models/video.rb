require "net/http"
require "cgi"
require "digest"
require "uri"

class Video < Content
  store_accessor :config, :url, :aspect_ratio, :audio, :tiktok_video_id

  OEMBED_OPEN_TIMEOUT = 5
  OEMBED_READ_TIMEOUT = 5
  OEMBED_CACHE_TTL = 24.hours
  OEMBED_ERROR_CACHE_TTL = 5.minutes

  YOUTUBE_HOSTS = %w[youtube.com www.youtube.com youtu.be].freeze
  VIMEO_HOSTS = %w[vimeo.com].freeze
  TIKTOK_HOSTS = %w[tiktok.com www.tiktok.com vm.tiktok.com vt.tiktok.com].freeze

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

  validates :url, presence: true
  validate :url_must_be_http
  validates :aspect_ratio, inclusion: { in: ASPECT_RATIOS }, allow_blank: true

  before_save :cache_tiktok_video_id, if: :url_changed_in_config?

  def as_json(options = {})
    super(options).merge({
      video_id: video_id,
      video_source: video_source,
      aspect_ratio: effective_aspect_ratio,
      aspect_ratio_auto: aspect_ratio.blank? || aspect_ratio == "auto",
      audio: audio?
    })
  end

  # Coerces the store_accessor string ("1"/"0"/"true"/"false") to a boolean.
  # Missing key (legacy records) reads as false.
  def audio?
    ActiveModel::Type::Boolean.new.cast(audio)
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

  # Allow videos in positions whose aspect ratio is within 4x of the video's
  # own, mirroring Graphic#fit_score. 4x keeps tickers and other extreme
  # banner shapes out while still allowing cross-orientation placement (e.g. a
  # 9:16 short in a 16:9 main), which is OK because the player letterboxes to
  # fit. A tighter 2x-3x bound is more shape-aware but rejects useful
  # cross-orientation cases.
  ASPECT_RATIO_TOLERANCE = 4.0

  # Score how well a video fits a position by aspect ratio: an exact match
  # scores 1.0, decaying to 0.0 at the edges of the tolerance window.
  def fit_score(position)
    width, height = effective_aspect_ratio.split("/").map(&:to_f)
    ratio = (width / height) / position.aspect_ratio

    return 0.0 unless ratio.between?(1.0 / ASPECT_RATIO_TOLERANCE, ASPECT_RATIO_TOLERANCE)

    1.0 - Math.log2(ratio).abs / Math.log2(ASPECT_RATIO_TOLERANCE)
  end

  def video_id
    return if url.blank?

    case video_source
    when "youtube"
      match = url.match(/(?:youtube\.com\/(?:shorts\/|[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/i)
      match[1] if match
    when "vimeo"
      match = url.match(/vimeo\.com\/(\d+)/)
      match[1] if match
    when "tiktok"
      if tiktok_video_id.present? && !url_changed_in_config?
        tiktok_video_id
      else
        extract_tiktok_video_id_from_oembed
      end
    end
  end

  def video_source
    return if url.blank?

    host = URI.parse(url).host&.downcase
    return if host.blank?

    if YOUTUBE_HOSTS.include?(host)
      "youtube"
    elsif VIMEO_HOSTS.include?(host)
      "vimeo"
    elsif TIKTOK_HOSTS.include?(host)
      "tiktok"
    end
  rescue URI::InvalidURIError
    nil
  end

  def searchable_data
    { name: name, body: url.to_s }
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

  def url_must_be_http
    return if url.blank?

    uri = URI.parse(url)
    unless uri.is_a?(URI::HTTP) && uri.host.present?
      errors.add(:url, "must be a valid http or https URL")
    end
  rescue URI::InvalidURIError
    errors.add(:url, "is not a valid URL")
  end

  def url_changed_in_config?
    new_record? || config_in_database&.dig("url") != url
  end

  def cache_tiktok_video_id
    if video_source == "tiktok"
      self.tiktok_video_id = extract_tiktok_video_id_from_oembed
    elsif config.is_a?(Hash)
      config.delete("tiktok_video_id")
    end
  end

  def extract_tiktok_video_id_from_oembed
    # Extract video ID from oEmbed data for better reliability and short URL support
    data = tiktok_oembed_data
    return unless data && data["html"]

    match = data["html"].match(/data-video-id="(\d+)"/)
    match[1] if match
  end

  # Memoized helper to fetch Vimeo oEmbed data once per request (backed by Rails.cache)
  def vimeo_oembed_data
    fetch_oembed_data("vimeo", "https://vimeo.com/api/oembed.json?url=#{CGI.escape(url)}")
  end

  # Memoized helper to fetch TikTok oEmbed data once per request (backed by Rails.cache)
  # This supports all TikTok URL formats including short links
  def tiktok_oembed_data
    fetch_oembed_data("tiktok", "https://www.tiktok.com/oembed?url=#{CGI.escape(url)}")
  end

  def fetch_oembed_data(provider, endpoint)
    return nil if url.blank?

    @oembed_cache ||= {}
    memo_key = [ provider, url ]
    return @oembed_cache[memo_key] if @oembed_cache.key?(memo_key)

    cache_key = "video:oembed:#{provider}:#{Digest::SHA256.hexdigest(url)}"
    cached = Rails.cache.read(cache_key)
    if cached == false
      return @oembed_cache[memo_key] = nil
    elsif cached.is_a?(Hash)
      return @oembed_cache[memo_key] = cached
    end

    uri = URI(endpoint)
    response = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: true,
      open_timeout: OEMBED_OPEN_TIMEOUT,
      read_timeout: OEMBED_READ_TIMEOUT
    ) { |http| http.get(uri.request_uri) }

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "Error fetching #{provider.capitalize} oEmbed data: HTTP #{response.code}"
      Rails.cache.write(cache_key, false, expires_in: OEMBED_ERROR_CACHE_TTL)
      return @oembed_cache[memo_key] = nil
    end

    data = JSON.parse(response.body)
    unless data.is_a?(Hash)
      Rails.logger.error "Error fetching #{provider.capitalize} oEmbed data: unexpected JSON payload"
      Rails.cache.write(cache_key, false, expires_in: OEMBED_ERROR_CACHE_TTL)
      return @oembed_cache[memo_key] = nil
    end

    Rails.cache.write(cache_key, data, expires_in: OEMBED_CACHE_TTL)
    @oembed_cache[memo_key] = data
  rescue StandardError => e
    Rails.logger.error "Error fetching #{provider.capitalize} oEmbed data: #{e.message}"
    Rails.cache.write(cache_key, false, expires_in: OEMBED_ERROR_CACHE_TTL)
    @oembed_cache[memo_key] = nil
  end
end

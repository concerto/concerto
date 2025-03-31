require "open-uri"

class Video < Content
  store_accessor :config, :url

  def as_json(options = {})
    super(options).merge({
      video_id: video_id,
      video_source: video_source
    })
  end

  # For now, videos should only be rendered in positions that are roughly
  # somewhere in the [4:3 - 16:9] range, with a large buffer.
  def should_render_in?(position)
    # I don't really know what these numbers should be, there
    # is room for tuning.
    (0.25 < position.aspect_ratio && position.aspect_ratio < 1)
  end

  def thumbnail_url
    "https://img.youtube.com/vi/#{video_id}/mqdefault.jpg"
  end

  def video_id
    if url.present?
      if video_source == "youtube"
        match = url.match(/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/i)
        match[1] if match
      elsif video_source == "vimeo"
        match = url.match(/vimeo\.com\/(\d+)/)
        match[1] if match
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
      if yt_hosts.include?(host)
        "youtube"
      elsif [ "vimeo.com" ].include?(host)
        "vimeo"
      end
    end
  end

  def thumbnail_url
    if video_source == "youtube"
      "https://img.youtube.com/vi/#{video_id}/mqdefault.jpg"
    elsif video_source == "vimeo"
      oembed_url = "https://vimeo.com/api/oembed.json?url=#{url}"
      begin
        response = OpenURI.open_uri(oembed_url).read
        data = JSON.parse(response)
        data["thumbnail_url"]
      rescue => e
        Rails.logger.error "Error fetching Vimeo thumbnail: #{e.message}"
        ""
      end
    else
      ""
    end
  end
end

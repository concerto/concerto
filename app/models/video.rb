class Video < Content
  store_accessor :config, :url

  def as_json(options = {})
    super(options).merge({
      video_id: video_id
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
      match = url.match(/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/i)
      match[1] if match
    end
  end
end

class Graphic < Content
  has_one_attached :image

  # URL Helpers are needed so we can generate a URL to the image in the JSON.
  include Rails.application.routes.url_helpers

  def as_json(options = {})
    super(options).merge({
        image: rails_blob_path(image, only_path: true)
    })
  end

  # Determine if a graphic fits in a position or not.
  #
  # If the height and width are known, the graphic will be
  # rendered in positions with an aspect ratio twice a small
  # or twice as large.
  #
  # There is room to improve this algorithm. I just made up 2.0.
  def should_render_in?(position)
    if !image.analyzed?
      logger.debug "graphic #{id} not analyzed, fallback rendering"
      return super
    end

    if image.metadata[:width].nil? || image.metadata[:height].nil?
      logger.debug "graphic #{id} broken analysis, w: #{image.metadata[:width]}, h: #{image.metadata[:height]}, fallback rendering}"
      return super
    end

    content_aspect_ratio = image.metadata[:width] / image.metadata[:height]
    position_aspect_ratio = position.aspect_ratio

    (position_aspect_ratio / 2.0) <= content_aspect_ratio && content_aspect_ratio <= (position_aspect_ratio * 2.0)
  end
end

class Graphic < Content
  has_one_attached :image do |attachable|
    attachable.variant :grid, resize_to_limit: [ nil, 400 ]
  end

  store_accessor :config, :conversion_error

  # URL Helpers are needed so we can generate a URL to the image in the JSON.
  include Rails.application.routes.url_helpers

  # Track image attachment changes for re-moderation
  before_save :track_image_change
  after_commit :reevaluate_submissions_for_image_change, on: [ :create, :update ]
  after_commit :convert_pdf_to_image_if_needed, on: [ :create, :update ]

  def as_json(options = {})
    super(options).merge({
        image: rails_blob_path(image, only_path: true)
    })
  end

  def processing?
    image.attached? && image.content_type == "application/pdf"
  end

  # Determine if a graphic fits in a position or not.
  #
  # If the height and width are known, the graphic will be
  # rendered in positions with an aspect ratio twice a small
  # or twice as large.
  #
  # There is room to improve this algorithm. I just made up 2.0.
  def should_render_in?(position)
    return false if processing?

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

  private

  def track_image_change
    @image_will_change = attachment_changes.key?("image")
  end

  def reevaluate_submissions_for_image_change
    return unless @image_will_change

    submissions.find_each(&:reevaluate_moderation!)
  end

  def convert_pdf_to_image_if_needed
    return unless @image_will_change && processing?

    update_column(:config, (config || {}).except("conversion_error")) if conversion_error.present?
    ConvertPdfToImageJob.perform_later(self)
  end
end

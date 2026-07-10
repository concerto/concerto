class Graphic < Content
  ANALYSIS_STUCK_AFTER = 60.seconds

  has_one_attached :image do |attachable|
    attachable.variant :grid, resize_to_limit: [ nil, 400 ]
    attachable.variant :preview, resize_to_limit: [ 1000, 1000 ]
  end

  store_accessor :config, :conversion_error

  # URL Helpers are needed so we can generate a URL to the image in the JSON.
  include Rails.application.routes.url_helpers

  # Track image attachment changes for re-moderation
  before_save :track_image_change
  after_commit :reevaluate_submissions_for_image_change, on: [ :create, :update ]
  after_commit :convert_pdf_to_image_if_needed, on: [ :create, :update ]

  validate :image_content_type_supported, if: -> { image.attached? }

  def as_json(options = {})
    super(options).merge({
        image: rails_blob_path(image, only_path: true)
    })
  end

  def processing?
    image.attached? && image.content_type == "application/pdf"
  end

  def analysis_stuck?
    image.attached? && image.variable? && !image.analyzed? &&
      image.created_at < ANALYSIS_STUCK_AFTER.ago
  end

  def searchable_data
    filename = image.attached? ? image.filename.to_s : nil
    { name: name, body: filename }
  end

  # Aspect ratios within this multiple of the position's are a fit; anything
  # more distorted is rejected. There is room to improve this. I just made up 2.0.
  ASPECT_RATIO_TOLERANCE = 2.0

  # Score how well a graphic fits a position based on aspect ratio.
  #
  # When the dimensions are known, a graphic scores highest in positions
  # whose aspect ratio matches its own, decaying to 0.0 at the edges of the
  # tolerance window (ratios more than ASPECT_RATIO_TOLERANCE times off).
  def fit_score(position)
    return 0.0 unless image.attached? && image.variable?

    if !image.analyzed?
      logger.debug "graphic #{id} not analyzed, fallback rendering"
      return super
    end

    if image.metadata[:width].nil? || image.metadata[:height].nil?
      logger.debug "graphic #{id} broken analysis, w: #{image.metadata[:width]}, h: #{image.metadata[:height]}, fallback rendering}"
      return super
    end

    content_aspect_ratio = image.metadata[:width].fdiv(image.metadata[:height])
    position_aspect_ratio = position.aspect_ratio
    ratio = content_aspect_ratio / position_aspect_ratio

    # Reject aspect ratios outside the tolerance window in either direction.
    return 0.0 unless ratio.between?(1.0 / ASPECT_RATIO_TOLERANCE, ASPECT_RATIO_TOLERANCE)

    # Grade by aspect-ratio closeness: an exact match scores 1.0, decaying to
    # 0.0 at the edges of the tolerance window.
    1.0 - Math.log2(ratio).abs / Math.log2(ASPECT_RATIO_TOLERANCE)
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

  def image_content_type_supported
    return if self.class.supported_content_types.include?(image.content_type)
    errors.add(:image, "type #{image.content_type} is not supported")
  end

  # Built lazily so ActiveStorage.variable_content_types has been populated by
  # its after_initialize hook before we read it (in production with eager
  # loading, a constant here would be evaluated before that hook runs, leaving
  # the list empty and rejecting every upload except PDF).
  def self.supported_content_types
    ActiveStorage.variable_content_types + [ "application/pdf" ]
  end
end

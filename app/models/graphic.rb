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

  # A graphic can only render once it has a displayable image: attached, in a
  # variable (non-PDF) format. PDFs stay unrenderable until the conversion
  # job replaces them with an image.
  def renderable?
    image.attached? && image.variable?
  end

  def analysis_stuck?
    image.attached? && image.variable? && !image.analyzed? &&
      image.created_at < ANALYSIS_STUCK_AFTER.ago
  end

  def searchable_data
    filename = image.attached? ? image.filename.to_s : nil
    { name: name, body: filename }
  end

  # A graphic is letterboxed into its position (object-fit: contain, see
  # ConcertoGraphic.vue), so fit_score grades the two things that follow from
  # the two shapes: how large the image renders, and how much of the box it
  # covers. Both derivations and the calibration behind every constant below
  # are in docs/content_fit_design.md.

  # Render size as a fraction of the largest this screen could show the image.
  # Measured against the screen, never the file: a 4K upload and a thumbnail
  # of the same shape score identically.
  SCALE_TARGET = 0.8
  SCALE_WEIGHT = 2.0

  # Too small to read. An 8.5x11 flyer in a ticker renders at 0.10.
  SCALE_MINIMUM = 0.15

  # Share of the box the image covers. A mismatch is normally just a cost —
  # what renders is whole and legible — but a shape that leaves the box
  # near-empty reads as a mistake, and scale cannot see it: every image wider
  # than the canvas reports the same scale in a given box, so only fill
  # separates a 16:9 photo from a 13:1 banner.
  LETTERBOX_WEIGHT = 0.75
  FILL_MINIMUM = 0.15

  # Score how well a graphic fits a position, in (0, 1]. 0.0 means the
  # position is not a candidate at all: the image would render too small to
  # read, or leave the box so empty it reads as a mistake.
  def fit_score(position)
    return 0.0 unless renderable?

    ratio = analyzed_aspect_ratio
    return super if ratio.nil?

    scale = rendered_scale(ratio, position)
    return 0.0 if scale < SCALE_MINIMUM

    fill = fill_fraction(ratio, position)
    return 0.0 if fill < FILL_MINIMUM

    Math.exp(-(scale_penalty(scale) + letterbox_penalty(fill)))
  end

  private

  # The image's own aspect ratio, or nil when analysis has not produced
  # usable dimensions and the caller should fall back to the base score.
  def analyzed_aspect_ratio
    unless image.analyzed?
      logger.debug "graphic #{id} not analyzed, fallback rendering"
      return nil
    end

    width, height = image.metadata.values_at(:width, :height)
    if width.nil? || height.nil?
      logger.debug "graphic #{id} broken analysis, w: #{width}, h: #{height}, fallback rendering"
      return nil
    end

    width.fdiv(height)
  end

  # Contained in a box, an image takes the height its tighter dimension
  # allows; normalising by the same figure for the whole canvas makes this
  # resolution-independent and bounded by 1.0.
  def rendered_scale(ratio, position)
    return 0.0 unless position.width.positive? && position.height.positive?

    contained_height(ratio, position.width, position.height) /
      contained_height(ratio, position.canvas_aspect_ratio, 1.0)
  end

  def contained_height(ratio, width, height)
    [ width / ratio, height ].min
  end

  # Too small is a defect; too large cannot happen, since rendered_scale is
  # capped at 1.0.
  def scale_penalty(scale)
    return 0.0 if scale >= SCALE_TARGET

    SCALE_WEIGHT * Math.log(SCALE_TARGET / scale)
  end

  # Contain matches one dimension exactly, so the share of the box covered is
  # just how far the two shapes are apart.
  def fill_fraction(ratio, position)
    relative = ratio / position.aspect_ratio
    relative > 1.0 ? 1.0 / relative : relative
  end

  def letterbox_penalty(fill)
    LETTERBOX_WEIGHT * -Math.log(fill)
  end

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

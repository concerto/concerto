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

  # A position and a graphic rarely have the same proportions, and the player
  # letterboxes the difference (object-fit: contain, see ConcertoGraphic.vue).
  # fit_score grades exactly that, and only that: the share of the box the
  # image ends up covering.
  #
  # Nothing here scores how *large* the image renders. A graphic may be a
  # poster covered in body text or a weather icon, and its metadata cannot
  # tell us which, so how big it ought to be is the template author's call
  # rather than ours. One consequence is worth relying on: a score depends
  # only on the two aspect ratios, so a position behaves the same at any size.
  # See docs/content_fit_design.md.

  # Below this the image covers so little of the box that it reads as a
  # mistake rather than a poor fit — a 13:1 banner in a portrait rail covers
  # 5%. This is the only thing that stops a graphic rendering, and it is
  # deliberately extreme; see Content#fit_score.
  FILL_MINIMUM = 0.15

  # How sharply the score falls away as space is wasted. Gentle on purpose:
  # covering half the box still scores 0.59, because an awkward fit should
  # lose to a better one rather than be ruled out.
  FILL_FALLOFF = 0.75

  # A graphic can only render once it has a displayable image: attached, in a
  # variable (non-PDF) format. PDFs stay unrenderable until the conversion
  # job replaces them with an image.
  def renderable?
    image.attached? && image.variable?
  end

  # Score how well a graphic fits a position, in (0, 1]. A score of 0.0 means
  # the image would leave the box so empty that the position is not a
  # candidate for it at all.
  def fit_score(position)
    return 0.0 unless renderable?

    ratio = analyzed_aspect_ratio
    return super if ratio.nil?

    fill = fill_fraction(ratio, position)
    return 0.0 if fill < FILL_MINIMUM

    fill**FILL_FALLOFF
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

  # Contain matches one dimension exactly, so the share of the box the image
  # covers is just how far the two shapes are apart.
  def fill_fraction(ratio, position)
    relative = ratio / position.aspect_ratio
    relative > 1.0 ? 1.0 / relative : relative
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

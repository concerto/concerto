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

  # A graphic is letterboxed into its position (object-fit: contain, see
  # ConcertoGraphic.vue), so the size it renders at and the space it leaves
  # empty both follow from the two shapes. fit_score grades exactly those:
  # how large the image renders, and how much of the box it wastes. This
  # mirrors RichText, which scores predicted font size and forced wrapping
  # (docs/content_fit_design.md).

  # Rendered size, as a fraction of the largest this screen could ever show
  # the image. At 1.0 the position constrains the image no more than the
  # screen itself does; below SCALE_TARGET the penalty grows.
  SCALE_TARGET = 0.8
  SCALE_WEIGHT = 2.0

  # Reserved for the extreme: a position that can only show the image as a
  # sliver, like an 8.5x11 flyer dropped into a ticker (0.10 of full size on
  # Blue Swoosh, a 2.4" strip on a 48" TV). Everything short of that is left
  # to the penalty above, because withholding content is worse than rendering
  # it awkwardly. Like RichText::FONT_MINIMUM this is a veto; see
  # Content#fit_score.
  #
  # 0.15 is the smallest value that still catches a flyer in every stock
  # template's ticker (the loosest, Ruby, renders it at 0.139). At that
  # setting the veto reaches only tickers and clock boxes; raising it to 0.20
  # starts disqualifying sidebars, which are a real place to put a graphic.
  #
  # Note this measures the render against the *screen*, never the file. A
  # 4K upload and a 160x90 thumbnail of the same shape score identically, so
  # resolution can neither trigger the veto nor rescue content from it.
  SCALE_MINIMUM = 0.15

  # Letterboxing is a cost: a shape mismatch wastes space, but what renders is
  # still whole and legible, so it is weighted well below the size term.
  LETTERBOX_WEIGHT = 0.75

  # It does become a veto at the extreme, though. Rendered scale cannot catch
  # this on its own: an image wider than the canvas is width-limited both in
  # the box and on the full screen, so the ratio cancels and every wide shape
  # scores the identical scale in a given box. A 16:9 photo and a 13:1 banner
  # both score 0.300 in the Blue Swoosh sidebar; one fills 38% of it and the
  # other 5%. Only fill tells them apart.
  #
  # 0.15 is calibrated on bamnet's read of the stock sidebar: 16:9 (0.38),
  # 758x307 (0.27) and both flyer orientations (0.52, 0.87) all look fine
  # there; 1331x99 (0.05) does not. Across every stock template this
  # withholds that banner and nothing else.
  FILL_MINIMUM = 0.15

  # A graphic can only render once it has a displayable image: attached,
  # in a variable (non-PDF) format. PDFs stay unrenderable until the
  # conversion job replaces them with an image.
  def renderable?
    image.attached? && image.variable?
  end

  # Score how well a graphic fits a position, in (0, 1]. A score of 0.0 means
  # the position cannot show this graphic at a useful size and is not a
  # candidate for it at all.
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

  # How large the image renders here, relative to the largest this screen
  # could show it. Contained in a box, an image renders at the height the
  # tighter of the two dimensions allows; comparing that against the same
  # figure for the whole canvas keeps the result resolution-independent and
  # bounded by 1.0.
  def rendered_scale(ratio, position)
    return 0.0 unless position.width.positive? && position.height.positive?

    contained_height(ratio, position.width, position.height) /
      contained_height(ratio, position.template.aspect_ratio, 1.0)
  end

  def contained_height(ratio, width, height)
    [ width / ratio, height ].min
  end

  # Too small is a defect; too large cannot happen, since rendered_scale is
  # capped at 1.0 by construction.
  def scale_penalty(scale)
    return 0.0 if scale >= SCALE_TARGET

    SCALE_WEIGHT * Math.log(SCALE_TARGET / scale)
  end

  # The share of the box the image actually covers once letterboxed into it.
  # Contain matches one dimension exactly, so this is just how far the two
  # shapes are apart.
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

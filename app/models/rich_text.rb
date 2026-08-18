class RichText < Content
    store_accessor :config, :render_as

    # render_as is an enum-like structure. Ideally we would use rails'
    # ActtiveRecord::Enum functionality, but it doesn't work store_accessor.
    def html? = render_as == "html"
    def plaintext? = render_as == "plaintext"

    def self.render_as
        { plaintext: "plaintext", html: "html" }
    end

    validates :render_as, inclusion: { in: RichText.render_as.values }, allow_nil: false
    validate :render_as_must_be_string

    def as_json(options = {})
        super(options).merge({
            render_as: render_as,
            text: text
        })
    end

    # Text metrics for predicting how the player's auto-fit will render a
    # string: average character width and line height, in em.
    CHAR_WIDTH = 0.5
    LINE_HEIGHT = 1.2
    # Positions store fractional coordinates, so comparing a position's width
    # against its height needs the screen's shape. Every shipped template
    # targets 16:9 displays.
    SCREEN_ASPECT = 16.0 / 9

    # Legibility band for the predicted font size, as a fraction of screen
    # height (resolution-independent: the same fraction is the same physical
    # size at 1080p and 4K). On a 48" TV the screen is ~23.5" tall, so the
    # target is ~1.4" text and the floor — below which walk-by viewers can't
    # read it — is ~0.8". Calibrated on Blue Swoosh: the floor sits between
    # a 2-line ticker (readable) and a 3-line ticker (not).
    FONT_TARGET = 0.06
    FONT_FLOOR = 0.035

    # Penalty weights, applied to the log-distance between the predicted
    # font and FONT_TARGET. Deliberately asymmetric: oversized text is fine
    # ("WELCOME STUDENTS" may render huge), undersized text is unreadable,
    # and below the floor it's a defect.
    ABOVE_TARGET_WEIGHT = 0.4
    BELOW_TARGET_WEIGHT = 3.0
    BELOW_FLOOR_WEIGHT = 4.0

    # Text is renderable whenever there is anything to show; whether a
    # position suits it is fit_score's concern, never a reason to drop it.
    def renderable?
      text.present?
    end

    # Score how legible this text will be in a position.
    #
    # The player auto-sizes text to the largest font that fits the position
    # (useTextResize.js), so the rendered font size is predictable from the
    # text length and the position's shape. Score that font against the
    # legibility band: 1.0 at FONT_TARGET, easing off for larger fonts, and
    # dropping steeply for smaller ones. See docs/content_fit_design.md.
    def fit_score(position)
      # HTML that strips to nothing (e.g. a bare link or embed) has no
      # measurable length; fall back to the base score so it still renders.
      plain = html? ? ActionController::Base.helpers.strip_tags(text.to_s) : text.to_s
      length = plain.strip.length
      return super if length.zero?

      legibility_score(predicted_font_fraction(length, position))
    end

    def searchable_data
      plain = html? ? ActionController::Base.helpers.strip_tags(text.to_s) : text.to_s
      { name: name, body: plain }
    end

    private

    # The font size the player's auto-fit lands on for `length` characters
    # in `position`, as a fraction of screen height. For each line count,
    # the position's height caps the font at height/(lines * LINE_HEIGHT)
    # and its width caps it at width * lines / (length * CHAR_WIDTH); the
    # auto-fit finds the line count that maximizes the smaller of the two.
    def predicted_font_fraction(length, position)
      width = (position.right - position.left) * SCREEN_ASPECT
      height = position.bottom - position.top

      best = 0.0
      1.step do |lines|
        by_height = height / (lines * LINE_HEIGHT)
        break if by_height <= best

        best = [ best, [ by_height, width * lines / (length * CHAR_WIDTH) ].min ].max
      end
      best
    end

    def legibility_score(font)
      return 0.0 unless font.positive?

      penalty = if font >= FONT_TARGET
        ABOVE_TARGET_WEIGHT * Math.log(font / FONT_TARGET)
      else
        BELOW_TARGET_WEIGHT * Math.log(FONT_TARGET / font)
      end
      penalty += BELOW_FLOOR_WEIGHT * Math.log(FONT_FLOOR / font) if font < FONT_FLOOR

      Math.exp(-penalty)
    end

    def render_as_must_be_string
        return if render_as.nil? || render_as.is_a?(String)

        errors.add(:render_as, "must be a string, not an array or other type")
    end
end

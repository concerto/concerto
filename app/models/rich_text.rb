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

    # Legibility band for the predicted font size, as a fraction of screen
    # height (resolution-independent: the same fraction is the same physical
    # size at 1080p and 4K). On a 48" TV the screen is ~23.5" tall, so the
    # target is ~1.4" text and the floor — below which walk-by viewers can't
    # read it — is ~0.8". Calibrated on Blue Swoosh: the floor sits between
    # a 2-line ticker (readable) and a 3-line ticker (not).
    FONT_TARGET = 0.06
    FONT_FLOOR = 0.035

    # Below this, text is not merely hard to read but illegible, and a
    # position offering only this is no position at all: a fit_score of 0.0
    # takes it out of the running entirely (see Content#fit_score). ~0.35" on
    # a 48" TV — readable from about three feet, which is not how anyone
    # meets a hallway screen. Deliberately far below FONT_FLOOR, which has to
    # stay a soft penalty: the two-line ticker render this model favours sits
    # just under the floor at ~0.8".
    FONT_MINIMUM = 0.015

    # Penalty weights, applied to the log-distance between the predicted
    # font and FONT_TARGET. Deliberately asymmetric: oversized text is fine
    # ("WELCOME STUDENTS" may render huge), undersized text is unreadable,
    # and below the floor it's a defect.
    ABOVE_TARGET_WEIGHT = 0.4
    BELOW_TARGET_WEIGHT = 3.0
    BELOW_FLOOR_WEIGHT = 4.0

    # Weight for line breaks the position forces on the author. Breaks the
    # author wrote are free — they are the shape the content was designed
    # for, so a field tall enough to honour them is a good home. Only
    # wrapping the box imposes is charged for, which is what separates a
    # two-line ticker from the same sentence poured into a ten-line column.
    WRAP_WEIGHT = 2.0

    # Bisection steps for the font search: far past float precision over the
    # (0, 1) range a font fraction lives in.
    FONT_SEARCH_STEPS = 48

    # HTML elements that begin a line of their own.
    BLOCK_ELEMENTS = %w[
      p div h1 h2 h3 h4 h5 h6 li ul ol blockquote pre hr
      section article header footer figure figcaption dl dt dd table tr
    ].freeze

    # Text is renderable whenever there is anything to show; whether a
    # position suits it is fit_score's concern, never a reason to drop it.
    def renderable?
      text.present?
    end

    # Score how well this text reads in a position.
    #
    # The player auto-sizes text to the largest font that fits the position
    # (useTextResize.js), so both the rendered font size and the line count
    # are predictable from the text and the position's shape. Text that would
    # render below FONT_MINIMUM is illegible and scores 0.0, taking the
    # position out of the running. Otherwise two penalties apply: how far the
    # font lands from the legibility band, and how much wrapping the position
    # had to impose to get there. Both are log-space distances, so they add.
    # See docs/content_fit_design.md.
    def fit_score(position)
      # HTML that strips to nothing (e.g. a bare link or embed) has no
      # measurable text; fall back to the base score so it still renders.
      segments = authored_segments
      return super if segments.empty?

      fit = predicted_fit(segments, position)
      return 0.0 if fit.font < FONT_MINIMUM

      Math.exp(-(legibility_penalty(fit.font) + wrap_penalty(fit)))
    end

    def searchable_data
      plain = html? ? ActionController::Base.helpers.strip_tags(text.to_s) : text.to_s
      { name: name, body: plain }
    end

    private

    Fit = Data.define(:font, :lines, :authored)
    private_constant :Fit

    # The lines the author actually wrote, as character counts.
    #
    # The player applies no white-space rule to rich text, so newlines in
    # plaintext collapse to spaces: plaintext is always one continuous run,
    # and every break in it is one a position imposed. HTML carries real
    # structure, and each block element or <br> is a line the author asked
    # for. Content that yields no segments has nothing measurable to show.
    def authored_segments
      unless html?
        length = text.to_s.strip.length
        return length.zero? ? [] : [ length ]
      end

      segments = []
      buffer = +""
      flush = lambda do
        stripped = buffer.strip
        segments << stripped.length unless stripped.empty?
        buffer.clear
      end

      visit = lambda do |node|
        node.children.each do |child|
          if child.text?
            buffer << child.text
          elsif child.name == "br"
            flush.call
          elsif BLOCK_ELEMENTS.include?(child.name)
            flush.call
            visit.call(child)
            flush.call
          else
            visit.call(child)
          end
        end
      end

      visit.call(Nokogiri::HTML.fragment(text.to_s))
      flush.call
      segments
    end

    # The font size the player's auto-fit lands on, as a fraction of screen
    # height, together with the line count it takes to get there.
    #
    # Each authored line wraps on its own, so the rendered line count is the
    # sum of every segment's wraps. Taller text at a given size needs a
    # smaller font, and lines * font is monotonic in font, so bisect for the
    # largest font whose lines still fit the height. For a single segment
    # this agrees with the closed form it replaces to full float precision.
    def predicted_fit(segments, position)
      # Positions store fractional coordinates, so a box's width only means
      # something next to its height once the canvas shape is folded in.
      # Position#width does exactly that (via Template#aspect_ratio, measured
      # from the template's background image), putting both dimensions in
      # screen-height units. Screens are not assumed to be 16:9 — portrait
      # and 4:3 templates work out on their own.
      width, height = position.width, position.height
      return Fit.new(font: 0.0, lines: 0, authored: segments.size) unless width.positive? && height.positive?

      low = Float::EPSILON
      high = height # always too tall: even one line needs font * LINE_HEIGHT
      FONT_SEARCH_STEPS.times do
        mid = (low + high) / 2
        if rendered_lines(segments, width, mid) * mid * LINE_HEIGHT <= height
          low = mid
        else
          high = mid
        end
      end

      Fit.new(font: low, lines: rendered_lines(segments, width, low), authored: segments.size)
    end

    # How many lines `segments` occupy at `font`, given each authored line
    # wraps independently. A font too big to fit even one character per line
    # never fits at all.
    def rendered_lines(segments, width, font)
      chars_per_line = width / (font * CHAR_WIDTH)
      return Float::INFINITY if chars_per_line < 1

      segments.sum { |length| [ (length / chars_per_line).ceil, 1 ].max }
    end

    # Charged only for the breaks the author did not write.
    def wrap_penalty(fit)
      return 0.0 unless WRAP_WEIGHT.positive? && fit.lines > fit.authored

      WRAP_WEIGHT * Math.log(fit.lines.to_f / fit.authored)
    end

    # How far the predicted font sits from the legibility band. Deliberately
    # asymmetric: oversized text is acceptable, undersized is not, and below
    # the floor it is a defect.
    def legibility_penalty(font)
      penalty = if font >= FONT_TARGET
        ABOVE_TARGET_WEIGHT * Math.log(font / FONT_TARGET)
      else
        BELOW_TARGET_WEIGHT * Math.log(FONT_TARGET / font)
      end
      penalty += BELOW_FLOOR_WEIGHT * Math.log(FONT_FLOOR / font) if font < FONT_FLOOR
      penalty
    end

    def render_as_must_be_string
        return if render_as.nil? || render_as.is_a?(String)

        errors.add(:render_as, "must be a string, not an array or other type")
    end
end

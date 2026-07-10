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

    # A "large" position takes up more than this fraction of the screen area.
    LARGE_AREA_THRESHOLD = 0.20
    # Large positions need at least this much text or it scales up too big.
    MIN_LARGE_POSITION_CHARS = 100
    # Rough character "capacity" of a position per unit of screen area,
    # calibrated so a position at LARGE_AREA_THRESHOLD holds
    # MIN_LARGE_POSITION_CHARS characters. These values are arbitrary and may
    # need tuning.
    CHARS_PER_AREA = MIN_LARGE_POSITION_CHARS / LARGE_AREA_THRESHOLD
    # How far text may run over a position's capacity before it's a poor fit.
    OVER_CAPACITY_FACTOR = 2.0

    # Score how well a piece of rich text fits a position based on its size.
    #
    # Text that is too short for a large position scales up to an
    # unreasonably large font; text that overflows a tiny position is
    # unreadable. Both are rejected (score 0.0). In between, the score peaks
    # when the text length is close to the position's capacity so the
    # best-fitting position ranks highest.
    def fit_score(position)
      # Don't render if there's no text.
      return 0.0 if text.blank?

      # Strip HTML for a more accurate character count.
      plain_text = ActionController::Base.helpers.strip_tags(text)
      return 0.0 if plain_text.blank?

      length = plain_text.length
      capacity = position.area * CHARS_PER_AREA

      if position.area > LARGE_AREA_THRESHOLD
        # Lower bound: keep short text out of large positions, where it would
        # scale up to an unreasonably large font.
        return 0.0 if length < MIN_LARGE_POSITION_CHARS
      else
        # Upper bound: keep walls of text out of small positions, where they
        # would overflow or shrink to an unreadable size.
        return 0.0 if length > capacity * OVER_CAPACITY_FACTOR
      end

      # Grade by how close the text length is to the position's capacity.
      capacity / (capacity + (length - capacity).abs)
    end

    def searchable_data
      plain = html? ? ActionController::Base.helpers.strip_tags(text.to_s) : text.to_s
      { name: name, body: plain }
    end

    private

    def render_as_must_be_string
        return if render_as.nil? || render_as.is_a?(String)

        errors.add(:render_as, "must be a string, not an array or other type")
    end
end

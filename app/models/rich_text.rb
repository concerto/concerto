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

    # Determine if a piece of rich text fits in a position or not.
    #
    # If the position is large and there's not a lot of text, it will
    # need to be scaled up and look unreasonable large. We should not
    # render it.
    def should_render_in?(position)
      # Don't render if there's no text.
      return false if text.blank?

      # Strip HTML for a more accurate character count.
      plain_text = ActionController::Base.helpers.strip_tags(text)
      return false if plain_text.blank?

      # This is a heuristic to prevent rendering a small amount of text
      # in a very large position, which would result in unreasonably
      # large font sizes.
      # A "large" position is one that takes up > 20% of the screen area.
      # A "small" amount of text is < 100 characters.
      # These values are arbitrary and may need tuning.
      return false if position.area > 0.20 && plain_text.length < 100

      # By default, rich text can be rendered.
      true
    end

    private

    def render_as_must_be_string
        return if render_as.nil? || render_as.is_a?(String)

        errors.add(:render_as, "must be a string, not an array or other type")
    end
end

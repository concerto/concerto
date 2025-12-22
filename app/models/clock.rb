# frozen_string_literal: true

class Clock < Content
  store_accessor :config, :format

  # Common format presets for the admin UI
  def self.formats
    {
      time_12h: "h:mm a",          # 12:34 PM
      date_short: "EEE, MMM d",    # Mon, Dec 21
      datetime_short: "h:mm a, MMM d"  # 2:34 PM, Dec 21
    }
  end

  validates :format, presence: true
  validate :format_must_be_string

  def as_json(options = {})
    super(options).merge({
      format: format
    })
  end

  private

  def format_must_be_string
    return if format.nil? || format.is_a?(String)

    errors.add(:format, "must be a string, not an array or other type")
  end
end

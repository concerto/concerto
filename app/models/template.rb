class Template < ApplicationRecord
  has_one_attached :image

  has_many :positions, dependent: :destroy
  accepts_nested_attributes_for :positions, reject_if: :all_blank, allow_destroy: true

  has_many :screens

  # Assumed canvas shape when the background image is missing or not yet
  # analyzed (e.g. right after upload, before the async analysis job runs).
  # Every seeded template is 16:9, so it's the safest default.
  DEFAULT_ASPECT_RATIO = 16.0 / 9.0

  # The canvas's real-world aspect ratio (width/height), inferred from the
  # background image. Positions store fractional (0-1) coordinates, which
  # only describe a shape once combined with this: a half-width box means
  # something very different on a 16:9 canvas than on a square one.
  def aspect_ratio
    return DEFAULT_ASPECT_RATIO unless image.attached? && image.analyzed?

    width = image.metadata[:width]
    height = image.metadata[:height]
    return DEFAULT_ASPECT_RATIO if width.nil? || height.nil?

    width.fdiv(height)
  end
end

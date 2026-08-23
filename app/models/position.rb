class Position < ApplicationRecord
  belongs_to :template
  belongs_to :field

  # The canvas this box's fractional coordinates are measured against.
  delegate :aspect_ratio, to: :template, prefix: :canvas

  # The box's dimensions in screen-height units: the stored coordinates are
  # fractions of the canvas, so the fractional width has to be scaled by the
  # canvas shape before it means anything alongside the height. Content models
  # size their render against these.
  def height
    (bottom - top).to_f
  end

  def width
    (right - left).to_f * canvas_aspect_ratio
  end

  # The position's real-world aspect ratio.
  def aspect_ratio
    width / height
  end
end

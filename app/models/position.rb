class Position < ApplicationRecord
  belongs_to :template
  belongs_to :field

  # The position's real-world aspect ratio: its fractional (0-1) box
  # corrected by the template canvas's actual pixel aspect ratio, since a
  # box's fractional width:height alone doesn't reflect its true shape on a
  # non-square canvas (see Template#aspect_ratio).
  def aspect_ratio
    (right-left).fdiv(bottom-top) * template.aspect_ratio
  end

  def area
    (right-left)*(bottom-top)
  end
end

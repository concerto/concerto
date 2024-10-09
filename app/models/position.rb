class Position < ApplicationRecord
  belongs_to :template
  belongs_to :field

  def aspect_ratio
    (right-left)/(bottom-top)
  end
end

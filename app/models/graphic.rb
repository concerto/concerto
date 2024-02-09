class Graphic < ApplicationRecord
  include ContentType

  has_one_attached :image
end

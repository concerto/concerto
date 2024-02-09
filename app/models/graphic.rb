class Graphic < ApplicationRecord
  has_one :content, as: :subtype

  accepts_nested_attributes_for :content

  has_one_attached :image
end

class Graphic < ApplicationRecord
  has_one :content, as: :subtype

  has_one_attached :image

  accepts_nested_attributes_for :content
end
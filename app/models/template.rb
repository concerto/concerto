class Template < ApplicationRecord
  has_one_attached :image

  has_many :positions, dependent: :destroy
  accepts_nested_attributes_for :positions, reject_if: :all_blank, allow_destroy: true

  has_many :screens
end

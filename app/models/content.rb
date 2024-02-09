class Content < ApplicationRecord
  belongs_to :subtype, polymorphic: true
end

module ContentType
  extend ActiveSupport::Concern

  included do
    has_one :content, as: :subtype

    accepts_nested_attributes_for :content
  end
end

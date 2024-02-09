class Content < ApplicationRecord
  belongs_to :subtype, polymorphic: true
end

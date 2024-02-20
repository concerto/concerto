class Position < ApplicationRecord
  belongs_to :template
  belongs_to :field
end

class Subscription < ApplicationRecord
  belongs_to :screen
  belongs_to :field
  belongs_to :feed
end

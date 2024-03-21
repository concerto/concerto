class Subscription < ApplicationRecord
  belongs_to :screen
  belongs_to :field
  belongs_to :feed

  def contents
    self.feed.content
  end
end

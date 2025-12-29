class Subscription < ApplicationRecord
  belongs_to :screen
  belongs_to :field
  belongs_to :feed

  validates :screen, :field, :feed, presence: true
  validates :feed_id, uniqueness: { scope: [ :screen_id, :field_id ], message: "is already subscribed to this field on this screen" }
  validates :weight, numericality: { only_integer: true, in: 1..10 }

  def contents
    self.feed.content
  end

  # Scope to find subscriptions for a specific screen and field
  scope :for_screen_and_field, ->(screen_id, field_id) { where(screen_id: screen_id, field_id: field_id) }
end

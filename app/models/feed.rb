class Feed < ApplicationRecord
    has_many :submissions, dependent: :destroy
    has_many :content, through: :submissions

    has_many :subscriptions, dependent: :destroy

    has_many :content, through: :submissions, source: :content

    # Determines if a feed allows users to upload content.
    def active_for_upload?
      true
    end
end

class Feed < ApplicationRecord
    belongs_to :group
    has_many :submissions, dependent: :destroy
    has_many :content, through: :submissions

    has_many :subscriptions, dependent: :destroy

    # Use FeedPolicy for Pundit authorization (including STI subclasses)
    def self.policy_class
      FeedPolicy
    end

    # Override in subclasses that should auto-approve submissions (e.g., RssFeed, RemoteFeed)
    def auto_approves_submissions?
      false
    end
end

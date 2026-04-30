class Feed < ApplicationRecord
    include Searchable

    belongs_to :group
    has_many :submissions, dependent: :destroy
    has_many :content, through: :submissions
    has_many :approved_submissions, -> { approved }, class_name: "Submission"
    has_many :approved_content, through: :approved_submissions, source: :content

    has_many :subscriptions, dependent: :destroy

    # Use FeedPolicy for Pundit authorization (including STI subclasses)
    def self.policy_class
      FeedPolicy
    end

    # Override in subclasses that should auto-approve submissions (e.g., RssFeed, RemoteFeed)
    def auto_approves_submissions?
      false
    end

    def searchable_data
      { name: name, body: description }
    end

    private

    # URL stripped of query string and fragment for use in search indexing.
    # Query parameters can carry secrets (API keys, signed tokens), and we
    # don't want those reaching the FTS corpus. Returns nil if the model has
    # no `url` (base Feed) or the value is blank/unparseable.
    def indexable_url
      raw = try(:url)
      return nil if raw.blank?

      uri = URI.parse(raw)
      uri.query = nil
      uri.fragment = nil
      uri.to_s
    rescue URI::InvalidURIError
      nil
    end
end

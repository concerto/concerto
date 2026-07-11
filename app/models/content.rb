class Content < ApplicationRecord
    include Searchable

    has_many :submissions, dependent: :destroy
    has_many :feeds, through: :submissions
    has_many :field_configs, foreign_key: :pinned_content_id, dependent: :nullify
    belongs_to :user

    # Use ContentPolicy for Pundit authorization (including STI subclasses)
    def self.policy_class
      ContentPolicy
    end

    # Re-evaluate moderation when content fields change
    after_update :reevaluate_submissions_moderation, if: :content_fields_changed?

    # Searchable: only index Content with at least one approved submission so
    # unapproved drafts don't consume search-result slots that policy_scope
    # would later filter out. The base class has no meaningful body — each STI
    # subclass overrides searchable_data with its own indexable text.
    def searchable?
      submissions.where(moderation_status: :approved).exists?
    end

    scope :active, -> { where("(start_time IS NULL OR start_time < :now) AND (end_time IS NULL OR end_time > :now)", { now: Time.current }) }
    scope :expired, -> { where("end_time IS NOT NULL AND end_time < :now", { now: Time.current }) }
    scope :upcoming, -> { where("start_time IS NOT NULL AND start_time > :now", { now: Time.current }) }
    scope :approved, -> { where(id: Submission.where(moderation_status: :approved).select(:content_id)) }
    scope :with_name_matching, ->(query) {
      where("LOWER(name) LIKE ?", "%#{sanitize_sql_like(query.to_s.downcase)}%")
    }

    # Scopes for RSS feed content filtering
    scope :unused, -> { expired.where(text: [ nil, "" ]).where("name LIKE ?", "%(unused)") }
    scope :used, -> { active.or(upcoming).or(expired.where.not(text: [ nil, "" ]).where.not("name LIKE ?", "%(unused)"))  }

    def as_json(options = {})
        options[:methods] ||= [ :type ]
        options[:only] ||= [ :id, :duration ]
        super(options)
    end

    # fit_score rates how well this content suits a given position.
    #
    # It returns a Float where 0.0 means "never render here" and larger
    # values indicate a better fit. Subclasses override this with
    # type-specific heuristics (see RichText and Graphic); the base class
    # has no size preferences, so everything fits equally.
    def fit_score(position)
      1.0
    end

    # Summarizes the overall moderation state of this content across all its
    # submissions. Highest-priority state wins so a single approved submission
    # surfaces as :approved even when other submissions are pending/rejected.
    # Reads from the loaded `submissions` association to play nicely with
    # `includes(:submissions)` on list views.
    def moderation_state
      statuses = submissions.map { |s| s.moderation_status.to_s }
      return :unsubmitted if statuses.empty?
      return :approved if statuses.include?("approved")
      return :pending  if statuses.include?("pending")
      :rejected
    end

    private

    # Fields that trigger re-moderation when changed
    # Includes 'config' for Video URL and RichText render_as changes
    # Note: 'name' is not tracked since it's not displayed in the player
    MODERATION_TRACKED_FIELDS = %w[text config duration start_time end_time].freeze

    def content_fields_changed?
      (saved_changes.keys & MODERATION_TRACKED_FIELDS).any?
    end

    def reevaluate_submissions_moderation
      submissions.find_each(&:reevaluate_moderation!)
    end
end

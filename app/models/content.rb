class Content < ApplicationRecord
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

    scope :active, -> { where("(start_time IS NULL OR start_time < :now) AND (end_time IS NULL OR end_time > :now)", { now: Time.current }) }
    scope :expired, -> { where("end_time IS NOT NULL AND end_time < :now", { now: Time.current }) }
    scope :upcoming, -> { where("start_time IS NOT NULL AND start_time > :now", { now: Time.current }) }
    scope :approved, -> { where(id: Submission.where(moderation_status: :approved).select(:content_id)) }

    # Scopes for RSS feed content filtering
    scope :unused, -> { expired.where(text: [ nil, "" ]).where("name LIKE ?", "%(unused)") }
    scope :used, -> { active.or(upcoming).or(expired.where.not(text: [ nil, "" ]).where.not("name LIKE ?", "%(unused)"))  }

    def as_json(options = {})
        options[:methods] ||= [ :type ]
        options[:only] ||= [ :id, :duration ]
        super(options)
    end

    # should_render_in? determines if a piece of content is
    # suitable to be rendered in a given position.
    #
    # By default, it returns true.
    def should_render_in?(position)
      true
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

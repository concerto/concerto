class Content < ApplicationRecord
    has_many :submissions, dependent: :destroy
    has_many :feeds, through: :submissions
    belongs_to :user

    scope :active, -> { where("(start_time IS NULL OR start_time < :now) AND (end_time IS NULL OR end_time > :now)", { now: Time.current }) }
    scope :expired, -> { where("end_time IS NOT NULL AND end_time < :now", { now: Time.current }) }
    scope :upcoming, -> { where("start_time IS NOT NULL AND start_time > :now", { now: Time.current }) }

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
end

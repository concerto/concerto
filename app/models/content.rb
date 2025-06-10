class Content < ApplicationRecord
    has_many :submissions, dependent: :destroy
    has_many :feeds, through: :submissions
    belongs_to :user

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

    # All content types share the same policy class.
    # This overrides how Pundit determines the policy class for models.
    def self.policy_class
      ContentPolicy
    end
end

class Content < ApplicationRecord
    has_many :submissions, dependent: :destroy
    has_many :feeds, through: :submissions

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

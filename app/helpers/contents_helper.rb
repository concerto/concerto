module ContentsHelper
    # Returns a +string+ of the path to render the partial for use in the grid view.
    #
    #   to_partial_path(graphic) # => "graphics/grid"
    def to_grid_partial_path(content)
        "#{ActiveSupport::Inflector.tableize(content.class.name)}/grid"
    end

    # Returns an HTML badge for the given content's moderation state, or nil
    # when the content is fully approved (no badge needed — the default case).
    MODERATION_BADGE_STYLES = {
        pending:     { label: "Pending",     classes: "bg-warning text-white" },
        rejected:    { label: "Rejected",    classes: "bg-error text-white" },
        unsubmitted: { label: "Not in feeds", classes: "bg-neutral-200 text-neutral-700" }
    }.freeze

    def moderation_state_badge(content)
        style = MODERATION_BADGE_STYLES[content.moderation_state]
        return nil unless style

        content_tag(:span, style[:label],
            class: "inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium #{style[:classes]}")
    end

    # Returns a +string+ summarizing the content's +start_time+ and +end_time+.
    #
    #   schedule_summary(content) # => "Always active"
    def schedule_summary(content)
        if content.start_time.nil? && content.end_time.nil?
            "Always active"
        elsif content.start_time.nil?
            "Shown until #{content.end_time}"
        elsif content.end_time.nil?
            "Shown after #{content.start_time}"
        else
            "Shown between #{content.start_time} and #{content.end_time}"
        end
    end
end

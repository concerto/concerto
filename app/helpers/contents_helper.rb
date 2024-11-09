module ContentsHelper
    # Returns a +string+ of the path to render the partial for use in the grid view.
    #
    #   to_partial_path(graphic) # => "graphics/grid"
    def to_grid_partial_path(content)
        "#{ActiveSupport::Inflector.tableize(content.class.name)}/grid"
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

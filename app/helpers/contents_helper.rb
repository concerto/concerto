module ContentsHelper
    # Returns a +string+ of the path to render the partial for use in the grid view.
    #
    #   to_partial_path(graphic) # => "graphics/grid"
    def to_grid_partial_path(content)
        "#{ActiveSupport::Inflector.tableize(content.class.name)}/grid"
    end
end

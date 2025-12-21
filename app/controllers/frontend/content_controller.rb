class Frontend::ContentController < Frontend::ApplicationController
  def index
    @screen = Screen.find(params[:screen_id])
    @field = Field.find(params[:field_id])
    @position = Position.find(params[:position_id])

    @content = []

    # Check for active pinned content
    # TODO: Refactor this when Content objects support a method to check if they are active or not.
    field_config = FieldConfig.find_by(screen: @screen, field: @field)
    if field_config&.pinned_content_id
      pinned = Content.active.find_by(id: field_config.pinned_content_id)
      @content = [ pinned ] if pinned
    end

    # Fallback to subscriptions if no active pinned content
    if @content.empty?
      @subscriptions = @screen.subscriptions.where(field_id: @field.id).to_a
      @content = @subscriptions.flat_map do |subscription|
        subscription.contents
      end

      # Remove content which should not be rendered in this position.
      # For example, a 4:3 graphic should probably not be rendered in a
      # long horizontal ticker field.
      @content.delete_if do |c|
        !c.should_render_in?(@position)
      end
    end

    logger.debug "Found #{@content.count} content to render in #{@screen.name}'s #{@field.name} field"

    render json: @content
  end
end

class Frontend::ContentController < Frontend::ApplicationController
  def index
    @screen = Screen.find(params[:screen_id])
    @field = Field.find(params[:field_id])

    @subscriptions = @screen.subscriptions.where(field_id: @field.id).to_a
    @content = @subscriptions.flat_map do |subscription|
      subscription.contents
    end

    logger.debug "Found #{@content.count} content to render in #{@screen.name}'s #{@field.name} field"

    render json: @content
  end
end

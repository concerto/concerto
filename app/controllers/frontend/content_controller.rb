class Frontend::ContentController < Frontend::ApplicationController
  before_action :set_field_config

  def index
    @position = Position.find(params[:position_id])

    @content = fetch_pinned_content || fetch_subscription_content

    logger.debug "Found #{@content.count} content to render in #{@screen.name}'s #{@field.name} field"

    render json: @content
  end

  private

  def set_field_config
    @screen = Screen.find(params[:screen_id])
    @field = Field.find(params[:field_id])
    @field_config = FieldConfig.find_by(screen: @screen, field: @field)
  end

  def fetch_pinned_content
    return nil unless @field_config&.pinned_content_id

    # TODO: Refactor this when Content objects support a method to check if they are active or not.
    pinned = Content.active.find_by(id: @field_config.pinned_content_id)
    [ pinned ] if pinned
  end

  def fetch_subscription_content
    subscriptions = @screen.subscriptions.where(field_id: @field.id)

    # Build content items with subscription metadata and filter by position compatibility
    content_items = subscriptions.flat_map do |subscription|
      subscription.contents.active.filter_map do |content|
        { content: content, subscription: subscription } if content.should_render_in?(@position)
      end
    end

    # Apply ordering strategy (defaults to "random" if no config or blank strategy)
    strategy = @field_config&.ordering_strategy.presence || "random"
    orderer = ContentOrderers.for(strategy)
    orderer.call(content_items)
  end
end

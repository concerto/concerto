class Frontend::ContentController < Frontend::ApplicationController
  before_action :set_field_config

  def index
    @position = Position.find(params[:position_id])

    @content = fetch_pinned_content || fetch_subscription_content

    logger.debug "Found #{@content.count} content to render in #{@screen.name}'s #{@field.name} field"

    @screen.touch(:last_seen_at)

    response.headers["X-Config-Version"] = @screen.config_version

    render json: @content
  end

  private

  def set_field_config
    @screen = Screen
      .includes(:field_configs, template: [ :positions, { image_attachment: :blob } ])
      .find(params[:screen_id])
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

    items = subscriptions.flat_map do |subscription|
      subscription.contents.active.map do |content|
        { content: content, subscription: subscription }
      end
    end

    # Dedupe across fields: when a feed is subscribed to several fields, keep
    # each piece of content only in the field where it fits best so it isn't
    # rendered in multiple positions at once. Content that fits nowhere on the
    # screen is dropped.
    best_field = best_field_by_content(items.map { |item| item[:content] })
    content_items = items.select { |item| best_field[item[:content].id] == @field.id }

    # Apply ordering strategy (defaults to "random" if no config or blank strategy)
    strategy = @field_config&.ordering_strategy.presence || "random"
    orderer = ContentOrderers.for(strategy)
    orderer.call(content_items)
  end

  # Maps each content id to the field id on this screen where it fits best.
  #
  # A content's candidate fields are those whose subscribed feed carries it.
  # Each field is scored via its position in the screen's template, and the
  # highest-scoring field wins (ties broken by lowest field id). Because this
  # only depends on the screen's subscriptions and template, every field's
  # independent request computes the same winner, so content lands in exactly
  # one field. Fields with no template position, or where the content has no
  # positive fit, are not eligible.
  def best_field_by_content(contents)
    content_ids = contents.map(&:id).uniq
    return {} if content_ids.empty?

    position_by_field = @screen.template.positions.index_by(&:field_id)
    contents_by_id = contents.index_by(&:id)

    # content_id => [field_id, ...] for every field on this screen carrying it
    field_ids_by_content = Submission.approved
      .where(content_id: content_ids)
      .joins(feed: :subscriptions)
      .where(subscriptions: { screen_id: @screen.id })
      .distinct
      .pluck(:content_id, "subscriptions.field_id")
      .group_by(&:first)

    content_ids.index_with do |content_id|
      content = contents_by_id[content_id]

      (field_ids_by_content[content_id] || [])
        .map(&:last)
        .uniq
        .filter_map do |field_id|
          position = position_by_field[field_id]
          score = position && content.fit_score(position)
          [ field_id, score ] if score&.positive?
        end
        .max_by { |field_id, score| [ score, -field_id ] }
        &.first
    end
  end
end

class ContentsController < ApplicationController
  before_action :authenticate_user!, only: :new
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  # GET /contents or /contents.json
  def index
    @scope = params[:scope] || "active"
    @query = params[:q].to_s.strip

    contents_scope = case @scope
    when "active"
                  Content.active
    when "upcoming"
                  Content.upcoming
    when "expired"
                  Content.expired
    else
                  Content.active
    end

    contents_scope = contents_scope.where(id: Search.matching_ids(@query, Content)) if @query.present?

    @contents = policy_scope(contents_scope).includes(:feeds)

    feed_buckets = @contents.group_by { |c| c.feeds.find { |f| f.is_a?(RssFeed) || f.is_a?(RemoteFeed) } }
    @feed_groups = feed_buckets.select { |feed, items| feed.present? && items.size > 3 }
    collapsed_ids = @feed_groups.values.flatten.map(&:id).to_set
    @primary_contents = @contents.reject { |c| collapsed_ids.include?(c.id) }
  end

  # GET /contents/new
  def new
    @content = Content.new
    authorize @content
  end
end

class ContentsController < ApplicationController
  before_action :authenticate_user!, only: :new
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  # GET /contents or /contents.json
  def index
    @scope = params[:scope].presence_in(%w[active upcoming expired mine]) || "active"
    # "mine" is meaningless without an authenticated owner; fall back to active.
    @scope = "active" if @scope == "mine" && !user_signed_in?
    @query = params[:q].to_s.strip

    contents_scope = case @scope
    when "active"   then Content.active
    when "upcoming" then Content.upcoming
    when "expired"  then Content.expired
    when "mine"     then Content.where(user_id: current_user.id)
    end

    if @query.present?
      contents_scope = if @scope == "mine"
        # Mine includes unapproved content which the search corpus excludes,
        # so fall back to a direct name match against the user's own uploads.
        like = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
        contents_scope.where("name LIKE ? COLLATE NOCASE", like)
      else
        contents_scope.where(id: Search.matching_ids(@query, Content))
      end
    end

    @contents = policy_scope(contents_scope).includes(:submissions)
  end

  # GET /contents/new
  def new
    @content = Content.new
    authorize @content
  end
end

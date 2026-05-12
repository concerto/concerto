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

    contents_scope = base_content_scope
    contents_scope = narrow_by_query(contents_scope) if @query.present?

    @contents = policy_scope(contents_scope).includes(:submissions)
  end

  # GET /contents/new
  def new
    @content = Content.new
    authorize @content
  end

  private

  def base_content_scope
    case @scope
    when "upcoming" then Content.upcoming
    when "expired"  then Content.expired
    when "mine"     then current_user.contents
    else                 Content.active
    end
  end

  # Mine surfaces pending/rejected/unsubmitted uploads, which the search
  # corpus excludes — so fall back to a direct name match on the user's
  # own content for that scope.
  def narrow_by_query(scope)
    if @scope == "mine"
      scope.with_name_matching(@query)
    else
      scope.where(id: Search.matching_ids(@query, Content))
    end
  end
end

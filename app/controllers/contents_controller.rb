class ContentsController < ApplicationController
  before_action :authenticate_user!, only: :new
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  # GET /contents or /contents.json
  def index
    @scope = params[:scope] || "active"

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

    @contents = policy_scope(contents_scope)
  end

  # GET /contents/new
  def new
    @content = Content.new
    authorize @content
  end
end

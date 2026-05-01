class SearchController < ApplicationController
  after_action :verify_authorized
  after_action :verify_policy_scoped

  def index
    # Search.call applies Pundit.policy_scope! per type internally — no single
    # record to authorize and no top-level scope to verify here.
    skip_authorization
    skip_policy_scope
    @query = params[:q].to_s.strip
    @results = @query.present? ? Search.call(@query, user: current_user) : []
  end
end

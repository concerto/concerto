class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @results = @query.present? ? Search.call(@query, user: current_user) : []
  end
end

class ContentsController < ApplicationController
  # Common parameters for creating a content
  PARAMS = [ :name, :duration, :start_time, :end_time, feed_ids: [] ].freeze

  # GET /contents or /contents.json
  def index
    @contents = Content.all
  end

  # GET /contents/new
  def new
    @content = Content.new
  end
end

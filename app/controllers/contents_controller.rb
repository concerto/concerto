class ContentsController < ApplicationController
  # GET /contents or /contents.json
  def index
    @contents = Content.all
  end

  # GET /contents/new
  def new
    @content = Content.new
  end
end

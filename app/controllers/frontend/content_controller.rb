class Frontend::ContentController < Frontend::ApplicationController
  def index
    @content = Content.all

    render json: @content
  end
end

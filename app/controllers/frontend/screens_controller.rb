class Frontend::ScreensController < ApplicationController
  layout false

  def show
    respond_to do |format|
      format.html
    end
  end

  def setup
    respond_to do |format|
      format.json { render :json => [] }
    end
  end
end

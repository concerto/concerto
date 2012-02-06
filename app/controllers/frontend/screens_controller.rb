class Frontend::ScreensController < ApplicationController
  layout 'frontend'

  def show
    respond_to do |format|
      format.html
    end
  end

  # GET /frontend/1/setup.json
  # Get information required to setup the screen
  # and display the template with positions.
  def setup
    begin
      @screen = Screen.find(params[:id])
    rescue ActiveRecord::ActiveRecordError
      render :json => {}, :status => 404
    else
      respond_to do |format|
        format.json {
          render :json => @screen.to_json(
            :only => [:name, :id],
            :include => {
              :template => {
                :include => {
                  :positions => {
                    :except => [:created_at, :updated_at, :template_id],
                  },
                },
                :only => [:id],
              }
            }
          )
        }
      end
    end
  end
end

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
      # Inject the path into an fake attribute so it gets sent with the setup info.
      @screen.template.path = frontend_screen_template_path(@screen, @screen.template)
      @screen.template.positions.each do |p|
        p.field_contents_path = frontend_screen_field_contents_path(@screen, p.field, :format => :json)
      end
      respond_to do |format|
        format.json {
          render :json => @screen.to_json(
            :only => [:name, :id],
            :include => {
              :template => {
                :include => {
                  :positions => {
                    :except => [:created_at, :updated_at, :template_id],
                    :methods => [:field_contents_path]
                  },
                },
                :only => [:id],
                :methods => [:path]
              }
            }
          )
        }
      end
    end
  end
end

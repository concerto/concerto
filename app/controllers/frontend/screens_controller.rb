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

      # Inject paths into fake attribute so they gets sent with the setup info.
      # Pretend that it's better not to change the format of the image, so we detect it's upload extension.
      if !@screen.template.media.original.first.nil?
        template_format = File.extname(@screen.template.media.original.first.file_name)[1..-1]
      else
        template_format = nil
      end
      @screen.template.path = frontend_screen_template_path(@screen, @screen.template, :format => template_format)      
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

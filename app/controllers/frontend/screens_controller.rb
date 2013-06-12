class Frontend::ScreensController < ApplicationController
  # Allow cross-origin resource sharing for screens#show.
  before_filter :allow_cors, :only => [:show]
  before_filter :screen_api
  
  layout 'frontend'

  def show
    begin
      @screen = Screen.find(params[:id])
    rescue ActiveRecord::ActiveRecordError
      # TODO: Could this just be a regular 404?
      render :text => "Screen not found.", :status => 404
    else
      auth!
      @js_files = ['frontend.js']
      if params[:debug]
        @js_files = ['frontend_debug.js']
      end
      if params[:files]
        @js_files = params[:files].split(",")
      end
      respond_to do |format|
        format.html
      end
    end
  end
  
  # GET /frontend
  # Handles legacy screens and stuff that doesn't know their id.
  def index
    if params[:mac]
      screen = Screen.find_by_mac(params[:mac])
      if screen
        redirect_to frontend_screen_path(screen), :status => :moved_permanently
      else
        render :text => "Screen not found.", :status => 404
      end
    else
      render :text => 'Bad request.', :status => 400
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
                    :except => [:created_at, :updated_at, :template_id, :field_id],
                    :methods => [:field_contents_path],
                    :include => {
                      :field => {
                        :only => [:id, :name]
                      }
                    }
                  },
                },
                :only => [:id],
                :methods => [:path]
              }
            }
          )
        }
      end
      @screen.mark_updated
    end
  end
end

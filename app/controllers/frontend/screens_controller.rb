class Frontend::ScreensController < ApplicationController
  # Allow cross-origin resource sharing for screens#show.
  before_filter :allow_cors, :only => [:show]
  before_filter :screen_api
  
  layout 'frontend'

  def show
    begin
      @screen = Screen.find(params[:id])
      auth!
    rescue ActiveRecord::ActiveRecordError
      # TODO: Could this just be a regular 404?
      render :text => "Screen not found.", :status => 404
    rescue CanCan::AccessDenied
      render :text=> "Screen requires authentication.", :status => 403
    else
      @js_files = ['frontend.js']
      @debug = false
      if params[:debug]
        @debug = true
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
  # Handles cases where the ID is not provided:
  #   public legacy screens screens - a MAC address is provided instead of an ID
  #   private screens - authentication token from a cookie is used instead of an ID
  #   private screen setup - a short token is stored in the session
  def index
    if params[:mac]
      screen = Screen.find_by_mac(params[:mac])
      if screen
        if screen.is_public?
          redirect_to frontend_screen_path(screen), :status => :moved_permanently
        else
          render :text => 'Forbidden.', :status => 403
        end
      else
        render :text => "Screen not found.", :status => 404
      end
    elsif session.has_key? :screen_temp_token
      @temp_token = session[:screen_temp_token]
      screen = Screen.find_by_temp_token @temp_token
      if screen.nil?
        render 'sign_in', :layout => "no-topmenu"
      else
        sign_in_screen screen
        redirect_to frontend_screen_path(screen), :status => :moved_permanently
      end
    elsif !current_screen.nil?
      redirect_to frontend_screen_path(current_screen), :status => :moved_permanently
    else
      # We're going to store the temporary token in the session.
      # We rely on rails's hash (based on a server-side key) to prevent spoofing,
      # since it will otherwise be very easy to steal the token.
      @temp_token = Screen.generate_temp_token
      session[:screen_temp_token] = @temp_token
      render 'sign_in', :layout => "no-topmenu"
    end  
  end

  # GET /frontend/1/setup.json
  # Get information required to setup the screen
  # and display the template with positions.
  def setup
    begin
      @screen = Screen.find(params[:id])
      auth! :action => :read
    rescue ActiveRecord::ActiveRecordError
      render :json => {}, :status => 404
    rescue CanCan::AccessDenied
      render :json => {}, :status => 403
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

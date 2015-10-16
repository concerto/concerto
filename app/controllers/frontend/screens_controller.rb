class Frontend::ScreensController < ApplicationController
  # Allow cross-origin resource sharing for screens#show.
  before_filter :allow_cors, only: [:show, :show_options]
  before_filter :screen_api
  
  layout 'frontend'

  # GET /frontend/:id
  def show
    @preview = params.has_key?(:preview) && params[:preview] == "true"
    begin
      @screen = Screen.find(params[:id])
      allow_screen_if_unsecured @screen
      auth! action: (@preview ? :preview : :display)
    rescue ActiveRecord::ActiveRecordError
      # TODO: Could this just be a regular 404?
      render text: "Screen not found.", status: 404
    rescue CanCan::AccessDenied
      if current_screen.nil?
        headers['WWW-Authenticate']='Basic realm="Frontend Screen"'
        render text: "Screen requires authentication.", status: 401
      else
        render text: "Incorrect authorization.", status: 403
      end
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
      @screen.run_callbacks(:frontend_display)
      respond_to do |format|
        format.html
      end
    end
  end

  # OPTIONS /frontend/:id
  # Requested by browser to find CORS policy
  def show_options
    head :ok
  end
  
  # GET /frontend
  # Handles cases where the ID is not provided:
  #   public legacy screens screens - a MAC address is provided instead of an ID
  #   private screens - send to ID based on authentication token from cookie or GET param
  #   private screen setup - a short token is stored in the session or GET param
  def index
    if !current_screen.nil?
      send_to_screen(current_screen)
    elsif params[:mac]
      screen = Screen.find_by_mac(params[:mac])
      if screen
        if screen.is_public?
          redirect_to frontend_screen_path(screen), status: :moved_permanently
        else
          render text: 'Forbidden.', status: 403
        end
      else
        render text: "Screen not found.", status: 404
      end
    elsif @temp_token = (session[:screen_temp_token] || params[:screen_temp_token])
      screen = Screen.find_by_temp_token @temp_token
      if screen.nil?
        send_temp_token
      else
        sign_in_screen screen
        complete_auth(screen)
      end
    else
      # We're going to store the temporary token in the session for
      # browser clients, and send it via the body for API requests.
      # Currently, the token is spoofable during the setup window,
      # but the consequences are limited.
      @temp_token = Screen.generate_temp_token
      session[:screen_temp_token] = @temp_token
      send_temp_token
    end  
  end

  def send_to_screen(screen)
    respond_to do |format|
      format.html { redirect_to frontend_screen_path(screen), status: :moved_permanently }
      format.json { render json: {
        screen_id: screen.id,
        screen_url: screen_url(screen),
        frontend_url: frontend_screen_url(screen)
     } }
    end
  end
  
  def send_temp_token 
    respond_to do |format|
      format.html { render 'sign_in', layout: "no-topmenu" }
      format.json { render json: {screen_temp_token: @temp_token} }
    end
  end

  def complete_auth(screen)
    respond_to do |format|
      format.html { redirect_to frontend_screen_path(screen), status: :moved_permanently }
      format.json { render json: {
        screen_auth_token: screen.screen_token
      } }
    end
  end

  # GET /frontend/1/setup.json
  # Get information required to setup the screen
  # and display the template with positions.
  def setup
    headers['Access-Control-Allow-Origin'] = '*' unless !ConcertoConfig[:public_concerto]
    @preview = params.has_key?(:preview) && params[:preview] == "true"
    begin
      @screen = Screen.find(params[:id])
      allow_screen_if_unsecured @screen
      auth! action: (@preview ? :preview : :display)
    rescue ActiveRecord::ActiveRecordError
      render json: {}, status: 404
    rescue CanCan::AccessDenied
      render json: {}, status: 403
    else

      field_configs = []  # Cache the field_configs
      @screen.run_callbacks(:frontend_display) do
        # Inject paths into fake attribute so they gets sent with the setup info.
        # Pretend that it's better not to change the format of the image, so we detect it's upload extension.
        if !@screen.template.media.preferred.first.nil?
          template_format = File.extname(@screen.template.media.preferred.first.file_name)[1..-1]
          @screen.template.path = frontend_screen_template_path(@screen, @screen.template, format: template_format)
        else
          template_format = nil
          @screen.template.path = nil
        end
        css_media = @screen.template.media.where({key: 'css'})
        if !css_media.empty?
          @screen.template.css_path = media_path(css_media.first)
        end
        @screen.template.positions.each do |p|
          p.field_contents_path = frontend_screen_field_contents_path(@screen, p.field, format: :json)
          p.field.config = {}
          FieldConfig.default.where(field_id: p.field_id).each do |d_fc|
            p.field.config[d_fc.key] = d_fc.value
            field_configs << d_fc
          end
          @screen.field_configs.where(field_id: p.field_id).each do |fc|
            p.field.config[fc.key] = fc.value
            field_configs << fc
          end
        end
      end

      @screen.time_zone = ActiveSupport::TimeZone::MAPPING[@screen.time_zone]

      if stale?(etag: @screen.frontend_cache_key, public: true)
      respond_to do |format|
        format.json {
          render json: @screen.to_json(
            only: [:name, :id, :time_zone],
            include: {
              template: {
                include: {
                  positions: {
                    except: [:created_at, :updated_at, :template_id, :field_id],
                    methods: [:field_contents_path],
                    include: {
                      field: {
                        methods: [:config],
                        only: [:id, :name, :config]
                      }
                    }
                  },
                },
                only: [:id, :name],
                methods: [:path, :css_path]
              }
            }
          )
        }
      end
      end
      unless @preview
        @screen.mark_updated
      end
    end
  end
end

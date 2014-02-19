class Frontend::ContentsController < ApplicationController
  define_callbacks :index  # controller callback
  ConcertoPlugin.install_callbacks(self) # Get the callbacks from plugins

  layout false

  before_filter :scope_setup
  before_filter :screen_api

  DEFAULT_SHUFFLE = 'WeightedShuffle'

  def scope_setup
    @screen = Screen.find(params[:screen_id])
    @screen.run_callbacks(:frontend_display) do
      @field = Field.find(params[:field_id])
      @subscriptions = @screen.subscriptions.where(:field_id => @field.id)
    end
  end

  def index
    require 'frontend_content_order'

    shuffle_config = FieldConfig.get(@screen, @field, 'shuffler') || DEFAULT_SHUFFLE
    shuffler_klass = FrontendContentOrder.load_shuffler(shuffle_config)
    session_key = "frontend_#{@screen.id}_#{@field.id}".to_sym
    shuffler = nil

    run_callbacks :index do # Run plugin hooks
      shuffler = shuffler_klass.new(@screen, @field, @subscriptions, session[session_key])
      @content = shuffler.next_contents()
    end
    
    auth! :object => @content
    session[session_key] = shuffler.save_session()

    begin
      @content.each do |c|
        c.pre_render(@screen, @field)
      end
    rescue Exception => e
      logger.warn e.message
    end

    response.headers["X-Concerto-Frontend-Setup-Key"] = Digest::MD5.hexdigest(@screen.frontend_cache_key)

    respond_to do |format|
      format.json {
        render :json => @content.to_json(
          :only => [:name, :id, :duration, :type],
          :methods => [:render_details]
        )
      }
    end
    @screen.sometimes_mark_updated
  end

  # GET /frontend/1/fields/1/contents/1
  # Trigger the render function a piece of content and passes all the params
  # along for processing.  Should send an inline result of the processing.
  def show
    @content = Content.find(params[:id])
    auth! :object=>@content
    rendered = @content.render(params)
    if rendered.is_a?(Media)
      @file = rendered
      send_data @file.file_contents, :filename => @file.file_name, :type => @file.file_type, :disposition => 'inline'
    elsif rendered.is_a?(Hash)
      render rendered
    end
  end
end

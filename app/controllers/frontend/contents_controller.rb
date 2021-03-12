class Frontend::ContentsController < ApplicationController
  define_callbacks :index  # controller callback
  ConcertoPlugin.install_callbacks(self) # Get the callbacks from plugins

  layout false

  before_filter :scope_setup
  before_filter :screen_api

  DEFAULT_SHUFFLE = 'WeightedShuffle'

  def scope_setup
    @screen = Screen.find(params[:screen_id])
    @field = Field.find(params[:field_id])
    @subscriptions = @screen.subscriptions.where(field_id: @field.id)
    allow_screen_if_unsecured @screen
  end

  def index
    allow_cors unless !ConcertoConfig[:public_concerto]
    require 'frontend_content_order'

    shuffle_config = FieldConfig.get(@screen, @field, 'shuffler') || DEFAULT_SHUFFLE
    shuffler_klass = FrontendContentOrder.load_shuffler(shuffle_config)
    shuffler = nil

    run_callbacks :index do # Run plugin hooks
      # Get the screen time and consider it the same time in the server time zone.
      # For instance 5pm at the eastern campus would be 5pm in mountain time
      # if our server is in mountain time zone.  This is because we consider the content
      # display range as "time without zone".  If a user wants an item to show from 8 to 5
      # then it should show from 8 to 5 on all screens regardless of time zone it
      # is in -- it should be considered "local time".
      actual_screen_time = DateTime.parse(Clock.time.in_time_zone(@screen.time_zone).iso8601)
      screen_time = Time.zone.local(
        actual_screen_time.year,
        actual_screen_time.month,
        actual_screen_time.day,
        actual_screen_time.hour,
        actual_screen_time.minute,
        actual_screen_time.second
      )

      shuffler = shuffler_klass.new(@screen, @field, @subscriptions)

      # get the contents from the shuffler and reject what this screen would consider expired
      @content = shuffler.remove_consecutive(shuffler.next_contents()).reject{ |c| c.start_time > screen_time || c.end_time < screen_time }
    end

    auth! object: @content

    begin
      @content.each do |c|
        c.pre_render(@screen, @field)
      end
    rescue Exception => e
      logger.warn e.message
    end

    # Rails.logger.debug("--frontend contentscontroller index is sending setup-key of #{@screen.frontend_cache_key}")
    response.headers["X-Concerto-Frontend-Setup-Key"] = @screen.frontend_cache_key
    response.headers["ETag"] = Digest::MD5.hexdigest(@screen.frontend_cache_key +
      @content.collect { |e| e.id.to_s + e.data.to_s }.to_s)
    respond_to do |format|
      format.json {
        render json: @content.to_json(
          only: [:name, :id, :duration, :type],
          methods: [:render_details]
        )
      }
    end
    @screen.sometimes_mark_updated
  end

  # GET /frontend/1/fields/1/contents/1
  # Trigger the render function a piece of content and passes all the params
  # along for processing.  Should send an inline result of the processing.
  def show
    allow_cors unless !ConcertoConfig[:public_concerto]
    
    #response.headers["Cache-Control"] = 'no-cache' # no-cache means revalidate at server before pulling from cache
    @content = Content.find(params[:id])
    if @content.nil?
      logger.info "Skipping Deleted Content with id " + params[:id]
    else
      auth! object:@content
      rendered = @content.render(params)
      if rendered.is_a?(Media)
        @file = rendered
        send_data @file.file_contents, filename: @file.file_name, type: @file.file_type, disposition: 'inline'
        #fresh_when last_modified: @file.updated_at.utc, etag: @file
      elsif rendered.is_a?(Hash)
        render rendered
      end
    end
  end
end

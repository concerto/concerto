class Frontend::ContentsController < ApplicationController
  layout false

  before_filter :scope_setup
  after_filter :dynamic_content_cron, :only => [:index]

  def scope_setup
    @screen = Screen.find(params[:screen_id])
    @field = Field.find(params[:field_id])
    @subscriptions = @screen.subscriptions.where(:field_id => @field.id)
  end

  def index
    content = @subscriptions.collect{|s| s.contents * s.weight}.flatten.shuffle!
    count = content.count
    @content = []
    if count > 0
      begin
        @content = [content[rand(count)]]
        @content.each do |c|
          c.pre_render(@screen, @field)
        end
      rescue Exception => e
        logger.warn e.message
      end
    end
    respond_to do |format|
      format.json {
        render :json => @content.to_json(
          :only => [:name, :id, :duration, :type],
          :methods => [:render_details]
        )
      }
    end
  end

  # GET /frontend/1/fields/1/contents/1
  # Trigger the render function a piece of content and passes all the params
  # along for processing.  Should send an inline result of the processing.
  def show
    @content = Content.find(params[:id])
    @file = @content.render(params)
    send_data @file.file_contents, :filename => @file.file_name, :type => @file.file_type, :disposition => 'inline'
  end


  private

  # Use the content#index requests as pings to think about updating the dynamic content.
  # This code needs to be really fast since it runs in the frontend and may block responses.
  def dynamic_content_cron
    if DynamicContent.should_cron_run?
      DynamicContent.delay.pid_locked_refresh
      DynamicContent.cron_ran()
    end
  end
end

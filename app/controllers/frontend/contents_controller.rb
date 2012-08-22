class Frontend::ContentsController < ApplicationController
  layout false

  before_filter :scope_setup

  def scope_setup
    @screen = Screen.find(params[:screen_id])
    @field = Field.find(params[:field_id])
  end

  def index
    count = @field.kind.contents.count
    @content = []
    if count > 0
      @content = [@field.kind.contents.first(:offset => rand(count))]
      @content.each do |c|
        c.pre_render(@screen, @field)
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

end

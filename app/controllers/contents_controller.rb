class ContentsController < ApplicationController
  before_filter :get_content_const, :only => [:new, :create]
  
  # Grab the constent object for the type of
  # content we're working with.  Probably needs
  # additional error checking.
  def get_content_const
    begin
      @content_const = params[:type].camelize.constantize
    rescue
      @content_const = nil
    end
  end

  # GET /contents
  # GET /contents.xml
  def index
    @contents = Content.all
    @content_display = params[:type] || 'table'
    @feeds = Feed.all
    if request.xhr?
      render :partial=> @content_display, :locals => {:contents => @contents, :is_ajax => true}
    else
      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @contents }
      end
    end
  end

  # GET /contents/1
  # GET /contents/1.xml
  def show
    @content = Content.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @content }
    end
  end

  # GET /contents/new
  # GET /contents/new.xml
  # Instantiate a new object of params[:type].
  # If params[:type] is nil, use graphics as the default.
  # If the object isn't valid (FooBar) or isn't a 
  # child of Content (Feed) a 400 error is thrown.
  def new
    #The default content type is "graphic"
    if params[:type].nil?
      @content_const = "graphic".camelize.constantize
    end
    
    #We don't recognize the content type, or
    #its not a child of Content.
    if @content_const.nil? || @content_const.superclass != Content
      render :nothing => true, :status => 400
    else
    
      @content = @content_const.new()
      
      respond_to do |format|
        format.html { } # new.html.erb
        format.xml  { render :xml => @content }
      end
    end
  end

  # GET /contents/1/edit
  def edit
    @content = Content.find(params[:id])
  end

  # POST /contents
  # POST /contents.xml
  def create
    @content =  @content_const.new(params[@content_const.model_name.singular])
    @feed_ids = []
    if params.has_key?("feed_id")
      @feed_ids = params[:feed_id].values
    end    

    respond_to do |format|
      if @content.save
        # Copy over the duration to each submission instance
        @feed_ids.each do |feed_id|
          @content.submissions << Submission.new({:feed_id => feed_id, :duration => @content.duration})
          #If you are the moderator,
          #then we might auto approve the submission here
        end
        @content.save #This second save adds the submissions
        format.html { redirect_to(@content, :notice => 'Content was successfully created.') }
        format.xml  { render :xml => @content, :status => :created, :location => @content }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @content.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /contents/1
  # PUT /contents/1.xml
  def update
    @content = Content.find(params[:id])

    respond_to do |format|
      if @content.update_attributes(params[:content])
        format.html { redirect_to(@content, :notice => 'Content was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @content.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /contents/1
  # DELETE /contents/1.xml
  def destroy
    @content = Content.find(params[:id])
    @content.destroy

    respond_to do |format|
      format.html { redirect_to(contents_url) }
      format.xml  { head :ok }
    end
  end

  # GET /contents/1/display
  # Trigger the render function a piece of content and passes all the params
  # along for processing.  Should send an inline result of the processing.
  def display
    @content = Content.find(params[:id])
    if stale?(:etag => params, :last_modified => @content.updated_at.utc, :public => true)
      @file = @content.render(params)
      send_data @file.file_data, :filename => @file.file_name, :type => @file.file_type, :disposition => 'inline'
    end
  end

end

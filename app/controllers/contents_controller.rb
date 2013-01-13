class ContentsController < ApplicationController
  before_filter :get_content_const, :only => [:new, :create]

  # Grab the constant object for the type of
  # content we're working with.  Probably needs
  # additional error checking.
  def get_content_const
    begin
      @content_const = params[:type].camelize.constantize
    rescue
      @content_const = nil
    end
  end

  # GET /contents/1
  # GET /contents/1.xml
  def show
    @content = Content.find(params[:id])
    @user = User.find(@content.user_id)
    auth!

    respond_to do |format|
      format.html #show.html.erb
      format.xml { render :xml => @content }
    end
  end

  # GET /contents/new
  # GET /contents/new.xml
  # Instantiate a new object of params[:type].
  # If the object isn't valid (FooBar) or isn't a
  # child of Content (Feed) a 400 error is thrown.
  def new
    # We might already have a content type, 
    if @content_const.nil? || !@content_const.ancestors.include?(Content)
      Rails.logger.debug "Content type #{@content_const} found not OK, trying default."
      default_upload_type = ConcertoConfig[:default_upload_type]
      if !default_upload_type
        raise "Missing Default Content Type"
      else
        @content_const = default_upload_type.camelize.constantize
      end
    end

    # We don't recognize the requested content type, or
    # its not a child of Content so we'll return a 400.
    if @content_const.nil? || !@content_const.ancestors.include?(Content)
      render :text => "Unrecognized content type.", :status => 400
    else
      @content = @content_const.new()
      auth!

      # TODO: Remove the fields the user does not have submission access to.
      @feeds = Feed.all

      respond_to do |format|
        format.html { } # new.html.erb
        format.xml  { render :xml => @content }
      end
    end
  end

  # GET /contents/1/edit
  def edit
    @content = Content.find(params[:id])
    auth!
  end

  # POST /contents
  # POST /contents.xml
  def create
    @content =  @content_const.new(content_params)
    @content.user = current_user
    auth!

    @feed_ids = []
    if params.has_key?("feed_id")
      @feed_ids = params[:feed_id].values
    end

    respond_to do |format|
      if @content.save
        # Copy over the duration to each submission instance
        @feed_ids.each do |feed_id|
          @feed = Feed.find(feed_id)
          #If a user can moderate the feed in question or is an admin - the content is automatically approved with their imprimatur
          if can?(:update, @feed) || user.is_admin?
            @content.submissions << Submission.new({:feed_id => feed_id, :duration => @content.duration, :moderation_flag => true, :moderator_id => current_user.id})
          else
            @content.submissions << Submission.new({:feed_id => feed_id, :duration => @content.duration})
          end
        end
        @content.save #This second save adds the submissions
        format.html { redirect_to(@content, :notice => t(:content_created)) }
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
    auth!

    respond_to do |format|
      if @content.update_attributes(content_params)
        submissions = @content.submissions
        submissions.each do |submission|
          submission.update_attributes(:moderation_flag => nil)
        end
        format.html { redirect_to(@content, :notice => t(:content_updated)) }
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
    auth!

    @content.destroy

    respond_to do |format|
      format.html { redirect_to(feeds_url) }
      format.xml  { head :ok }
    end
  end

  # GET /contents/1/display
  # Trigger the render function a piece of content and passes all the params
  # along for processing.  Should send an inline result of the processing.
  def display
    @content = Content.find(params[:id])
    auth!(:action => :read)
    if stale?(:etag => params, :last_modified => @content.updated_at.utc, :public => true)
      @file = nil
      data = nil
      benchmark("Content#render") do
        @file = @content.render(params)
        data = @file.file_contents
      end
      send_data data, :filename => @file.file_name, :type => @file.file_type, :disposition => 'inline'
    end
  end

private

  # Restrict the allowed parameters to a select set defined in the model.
  def content_params
    # First we need to figure out the model name.
    content_sym = :content
    attributes = Content.form_attributes
    if !@content_const.nil?
      content_sym = @content_const.model_name.singular.to_sym
      attributes = @content_const.form_attributes
    end
    # Reach into the model and grab the attributes to accept.
    params.require(content_sym).permit(*attributes)
  end

end

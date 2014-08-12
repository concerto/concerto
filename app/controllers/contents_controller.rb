class ContentsController < ApplicationController
  before_filter :get_content_const, :only => [:new, :create, :update, :preview]
  respond_to :html, :json, :js

  define_callbacks :update_params
  ConcertoPlugin.install_callbacks(self)

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

  def index
    @content = Content.filter_all_content(params)
    @content = Kaminari.paginate_array(@content).page(params[:page])

    respond_to do |format|
      format.html
      format.js {render :json => @content}
    end
  end

  # GET /contents/1
  # GET /contents/1.xml
  def show
    @content = Content.find(params[:id])
    @user = User.find(@content.user_id)
    auth!

    respond_with(@content)

  rescue ActiveRecord::RecordNotFound
    # while it could be returned as a 404, we should keep the user in the application
    # render :text => "Requested content not found", :status => 404
    respond_to do |format|
      format.html { redirect_to(browse_path, :notice => t(:content_not_found)) }
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
        raise t(:missing_default_type)
      else
        @content_const = default_upload_type.camelize.constantize
      end
    end

    # We don't recognize the requested content type, or
    # its not a child of Content so we'll return a 400.
    if @content_const.nil? || !@content_const.ancestors.include?(Content)
      render :text => t(:unrecognized_type), :status => 400
    else
      @content = @content_const.new()
      @content.duration = ConcertoConfig[:default_content_duration].to_i
      auth!
      @feeds = submittable_feeds
      respond_with(@content)
    end
  end

  def add_feed
    @feed = Feed.find(params[:feed_id])
    @feed_index = params[:feed_index]

    respond_to do |format|
      format.js
    end
  end

  # GET /contents/1/edit
  def edit
    @content = Content.find(params[:id])
    auth!
    @feeds = submittable_feeds
  end

  # POST /contents
  # POST /contents.xml
  def create
    prams = content_params
    if prams.include?("media_attributes") && prams[:media_attributes]["0"].include?("id")
      # pull out the media_id otherwise, new will try to find it even though it's not yet linked
      media_id = prams[:media_attributes]["0"][:id]
      prams[:media_attributes]["0"].delete :id
    end
    # some content, like the ticker_text, can have a kind other than it's model's default
    if prams.include?("kind_id")
      kind = Kind.find(prams[:kind_id])
      prams.delete :kind_id
    end
    @content = @content_const.new(prams)
    @content.kind = kind if !kind.nil?
    @content.user = current_user
    auth!

    @feed_ids = feed_ids

    remove_empty_media_param
    if !media_id.blank?
      # if the media_id was passed in then there is an existing media
      # record that needs to be attached to this content
      @media = Media.find(media_id)
      # only reassign if not already assigned
      if @media[:key] == 'preview' && @media[:attachable_id] == 0
        @media[:key] = 'original'
        @content.media.clear
        @content.media.concat(@media)
      end
    end
    respond_to do |format|
      # remove the media entry added in the _form_top partial if it is completely empty
      @content.media.reject! { |m| m.file_name.nil? && m.file_type.nil? && m.file_size.nil? && m.file_data.nil? }
      begin
        results = @content.save
      rescue Concerto::ContentConverter::Unconvertable => e
        results = false
        flash.now[:error] = e.message
      rescue StandardError => e
         results = false
         flash.now[:error] = e.message
      end
      if results
        process_notification(@content, {}, process_notification_options({
          :params => {
            :content_name => @content.name,
            :content_type => @content.class.model_name.human
          },
          :key => "content.#{action_name}"}))
        # Copy over the duration to each submission instance
        create_submissions
        @content.save #This second save adds the submissions
        if @feed_ids == []
          format.html { redirect_to(@content, :notice => t(:content_created_no_feeds)) }
          format.xml { render :xml => @content, :status => :created, :location => @content }
        else
          format.html { redirect_to(@content, :notice => t(:content_created)) }
          format.xml { render :xml => @content, :status => :created, :location => @content }
        end
      else
        @feeds = submittable_feeds
        format.html { render :action => "new" }
        format.xml { render :xml => @content.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /contents/1
  # PUT /contents/1.xml
  def update
    @content = Content.find(params[:id])
    @user = User.find(@content.user_id)
    auth!

    @feed_ids = feed_ids

    if @content.update_attributes(content_update_params)
      process_notification(@content, {}, process_notification_options({
        :params => {
          :content_name => @content.name,
          :content_type => @content.class.model_name.human
        },
        :key => "content.#{action_name}"}))
      submissions = @content.submissions
      submissions.each do |submission|
        if @feed_ids.include? submission.feed_id
          submission.update_attributes(:moderation_flag => nil)
        else
          submission.mark_for_destruction
        end
      end
      submitted_feeds = submissions.map { |s| s.feed_id }
      @feed_ids.reject! { |id| submitted_feeds.include? id }
      create_submissions
      if @content.save
        flash[:notice] = t(:content_updated)
      end
      respond_with(@content)
    else
      @feeds = submittable_feeds
      respond_with(@content)
    end
  end

  # DELETE /contents/1
  # DELETE /contents/1.xml
  def destroy
    @content = Content.find(params[:id])
    auth!

    process_notification(@content, {}, process_notification_options({
      :params => {
        :content_name => @content.name,
        :content_type => @content.class.model_name.human
       },
      :key => "content.#{action_name}"}))
    @content.destroy

    respond_to do |format|
      format.html { redirect_to(feeds_url) }
      format.xml { head :ok }
    end
  end

  # GET /contents/1/display
  # Trigger the render function a piece of content and passes all the params
  # along for processing.  Should send an inline result of the processing.
  def display
    # To support graphic preview where there isnt any content yet, create an unsaved
    # piece of content owned by the current user and associate the preview media with it.
    if params[:id] == "preview" && params[:type].present?
      get_content_const
      @content = @content_const.new(:user => current_user)
      media = Media.valid_preview(params[:media_id])
      if media.nil?
        raise ActiveRecord::RecordNotFound
      end
      @content.media << media
    else
      @content = Content.find(params[:id])
    end

    auth!(:action => :read)
    # if handling graphic preview (the content id is 0), force a render
    if params[:id] == "preview" || stale?(:etag => params, :last_modified => @content.updated_at.utc, :public => true)
      @file = nil
      data = nil
      benchmark("Content#render") do
        @file = @content.render(params)
        data = @file.file_contents
      end
      send_data data, :filename => @file.file_name, :type => @file.file_type, :disposition => 'inline'
    end
  end

  # PUT /contents/1/act
  # Trigger custom actions for the content.
  def act
    @content = Content.find(params[:id])
    auth!(:action => :read)
    action_name = params[:action_name].to_sym
    params[:current_user] = current_user
    result = @content.perform_action(action_name, params)

    respond_to do |format|
      format.html do
        # reload to get the updated information
        @content = Content.find(params[:id])
        @user = User.find(@content.user_id)

        flash.now[:notice] = (result.nil? ? 'Unable to perform action' : result)
        render :show
      end
      format.js do
        if result.nil?
          render :text => 'Unable to perform action.', :status => 400
        else
          render :text => result, :status => 200
        end
      end
    end
  end

  # returns the content types preview of the specified data or looked up by id
  def preview
    data = ""
    if !params[:data].nil?
      data = params[:data]
    elsif !params[:id].nil?
      content = Content.find(params[:id])
      data = content[:data] unless content.nil?
    end

    html = "Unrecognized content type"
    if !@content_const.nil?
      html = @content_const.preview(data)
    end
    respond_to do |format|
      format.html { render :text => html, :layout => false }
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

  # Use an extra restrictive list of params for content updates.
  def content_update_params
    run_callbacks :update_params do
      @content_sym = :content
      if !@content_const.nil?
        @content_sym = @content_const.model_name.singular.to_sym
      end
      @attributes = [:name, :duration, {:start_time => [:time, :date]}, {:end_time => [:time, :date]}]
    end
    params.require(@content_sym).permit(*@attributes)
  end

  def submittable_feeds
    Feed.accessible_by(current_ability, :submit_content)
  end

  def feed_ids
    feed_ids = params[:feed_id].map { |i, n| n.to_i } if params.has_key?("feed_id")
    feed_ids ||= []
  end

  def remove_empty_media_param
    @content.media.reject! { |m| m.file_name.nil? && m.file_type.nil? && m.file_size.nil? && m.file_data.nil? }
  end

  def create_submissions
    @feed_ids.each do |feed_id|
      @feed = Feed.find(feed_id)
      #If a user can moderate the feed in question the content is automatically approved with their imprimatur
      if can?(:update, @feed)
        @content.submissions << Submission.new({:feed_id => feed_id, :duration => @content.duration, :moderation_flag => true, :moderator_id => current_user.id})
      else
        @content.submissions << Submission.new({:feed_id => feed_id, :duration => @content.duration})
      end
    end
  end
end

class FeedsController < ApplicationController
  rescue_from ActionView::Template::Error, with: :precompile_error_catch
  respond_to :html, :json
  
  # GET /feeds
  # GET /feeds.xml
  # GET /feeds.js
  def index
    if !ConcertoConfig[:public_concerto]
      redirect_to(new_user_session_path)
    else
      @motd = ConcertoConfig.get(:motd_html)
      @feeds = Feed.accessible_by(current_ability).roots
      respond_with(@feeds)
    end
  end

  # GET /moderate
  # GET /moderate.js
  def moderate
    # We first get all feeds the accessor can index (update => index permission)
    @feeds = Feed.accessible_by(current_ability, :index)
    # Remove those feeds the accessor has index permission but not update
    auth!(object: @feeds, action: :update, allow_empty: false)
    @feeds.to_a.reject!{|f| not f.pending_contents.count > 0}
    
    respond_to do |format|
      format.html { }
      format.js { }
    end
  end

  # GET /feeds/1
  # GET /feeds/1.xml
  # GET /feeds/1.js
  def show
    @feed = Feed.find(params[:id])
    auth!

    respond_to do |format|
      format.html { redirect_to(feed_submissions_path(@feed)) }
      format.xml  { render xml: @feed }
      format.js { render layout: false }
    end
  end

  # GET /feeds/new
  # GET /feeds/new.xml
  def new
    @feed = Feed.new
    auth!
    
    #populate the checkboxes for content types by default when creating a new feed
    Concerto::Application.config.content_types.each do |type|
      @feed.content_types[type.name] = "1"
    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @feed }
    end
  end

  # GET /feeds/1/edit
  def edit
    @feed = Feed.find(params[:id])
    auth!
  end

  # POST /feeds
  # POST /feeds.xml
  def create
    @feed = Feed.new(feed_params)
    auth!
    if @feed.save
      process_notification(@feed, {}, process_notification_options({params: {feed_name: @feed.name}}))
      flash[:notice] = t(:feed_created)
    end
    respond_with(@feed)
  end

  # PUT /feeds/1
  # PUT /feeds/1.xml
  def update
    @feed = Feed.find(params[:id])
    auth!

    respond_to do |format|
      if @feed.update_attributes(feed_params)
        process_notification(@feed, {}, process_notification_options({params: {feed_name: @feed.name}}))
        format.html { redirect_to(feed_submissions_path(@feed), notice: t(:feed_updated)) }
        format.xml  { head :ok }
      else
        format.html { render action: "edit" }
        format.xml  { render xml: @feed.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /feeds/1
  # DELETE /feeds/1.xml
  def destroy
    @feed = Feed.find(params[:id])
    auth!
    process_notification(@feed, {}, process_notification_options({params: {feed_name: @feed.name}}))
    @feed.destroy
    respond_with(@feed)
  end

private

  def feed_params
    types = Concerto::Application.config.content_types.map{|t| t.name.to_sym}
    params.require(:feed).permit(:name, :description, :parent_id, :group_id, :is_viewable, :is_submittable, content_types: types)
  end

end

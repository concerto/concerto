class FeedsController < ApplicationController
  # GET /feeds
  # GET /feeds.xml
  # GET /feeds.js
  def index
    @feeds = Feed.roots
    @screens = Screen.all
    auth!(:object => @screens)
    auth!

    respond_to do |format|
      format.html { } # index.html.erb
      format.xml  { render :xml => @feeds }
      format.js { render :layout => false }
    end
  end

  # GET /moderate
  # GET /moderate.js
  def moderate
    @feeds = Feed.all
    auth!(:object => @feeds, :action => :update, :allow_empty => false)
    @feeds.reject!{|f| not f.pending_contents.count > 0}
    
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
      format.xml  { render :xml => @feed }
      format.js { render :layout => false }
    end
  end

  # GET /feeds/new
  # GET /feeds/new.xml
  def new
    @feed = Feed.new
    auth!

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @feed }
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

    respond_to do |format|
      if @feed.save
        format.html { redirect_to(:action => :index, :notice => t(:feed_created)) }
        format.xml  { render :xml => @feed, :status => :created, :location => @feed }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @feed.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /feeds/1
  # PUT /feeds/1.xml
  def update
    @feed = Feed.find(params[:id])
    auth!

    respond_to do |format|
      if @feed.update_attributes(feed_params)
        format.html { redirect_to(@feed, :notice => t(:feed_updated)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @feed.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /feeds/1
  # DELETE /feeds/1.xml
  def destroy
    @feed = Feed.find(params[:id])
    auth!
    @feed.destroy

    respond_to do |format|
      format.html { redirect_to(feeds_url) }
      format.xml  { head :ok }
    end
  end

private

  def feed_params
    types = Concerto::Application.config.content_types.map{|t| t.name.to_sym}
    params.require(:feed).permit(:name, :description, :parent_id, :group_id, :is_viewable, :is_submittable, :content_types => types)
  end

end

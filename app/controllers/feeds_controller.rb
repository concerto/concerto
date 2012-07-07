class FeedsController < ApplicationController
  # GET /feeds
  # GET /feeds.xml
  def index
    @feeds = Feed.roots
    auth!

    respond_to do |format|
      format.html { } # index.html.erb
      format.xml  { render :xml => @feeds }
      format.js { render :layout => false }
    end
  end

  # GET /feeds/1
  # GET /feeds/1.xml
  def show
    @feed = Feed.find(params[:id])
    auth!

    respond_to do |format|
      format.html { } # show.html.erb
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
    @feed = Feed.new(params[:feed])
    auth!

    respond_to do |format|
      if @feed.save
        format.html { redirect_to(@feed, :notice => t(:feed_created)) }
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
      if @feed.update_attributes(params[:feed])
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
end

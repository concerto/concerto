class FeedsController < ApplicationController
  rescue_from ActionView::Template::Error, :with => :precompile_error_catch
  
  # GET /feeds
  # GET /feeds.xml
  # GET /feeds.js
  def index
    @feeds = Feed.roots
    @screens = Screen.all
    auth!(:object => @screens)
    auth!
    get_activities()
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
    
    #populate the checkboxes for content types by default when creating a new feed
    Concerto::Application.config.content_types.each do |type|
      @feed.content_types[type.name] = "1"
    end

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
        process_notification(@feed, {:public_owner => current_user.id}, :action => 'create')
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
    process_notification(@feed, {:public_owner => current_user.id, :feed_name => @feed.name}, :action => 'destroy')
    @feed.destroy
    respond_to do |format|
      format.html { redirect_to(feeds_url) }
      format.xml  { head :ok }
    end
  end

private

  def get_activities
    @activities = []
    if current_user && defined? PublicActivity::Activity
      #Retrieve the activities for which the current user is an owner or recipient (making sure the STI field specifies user as the Type)       
      owner = PublicActivity::Activity.where(:owner_id => current_user.id, :owner_type => 'User').limit(25)  
      recipient = PublicActivity::Activity.where(:recipient_id => current_user.id, :recipient_type => 'User').limit(25)
      
      #Select the activities that involve a group as the recipient for which the user is a member
      group_member = PublicActivity::Activity.where(:recipient_id => current_user.group_ids, :recipient_type => "Group").limit(10)
        
      #Select activities with neither an owner nor a recipient (public activities) - the actual owner is set in the parameters hash for these
      public_activities = PublicActivity::Activity.where(:owner_id => nil, :recipient_id => nil).limit(10)
      
      @activities = owner + recipient + group_member + public_activities
      @activities.sort! { |a,b| b.created_at <=> a.created_at }
    end
  end

  def feed_params
    types = Concerto::Application.config.content_types.map{|t| t.name.to_sym}
    params.require(:feed).permit(:name, :description, :parent_id, :group_id, :is_viewable, :is_submittable, :content_types => types)
  end

end

class SubscriptionsController < ApplicationController
  before_filter :get_screen, :get_field
  
  def get_screen
    @screen = Screen.find(params[:screen_id])
  end

  def get_field
    @field = Field.find(params[:field_id])
  end

  # GET /screens/:screen_id/fields/:field_id/subscriptions
  # GET /screens/:screen_id/fields/:field_id/subscriptions.xml
  def index
    @subscriptions = @screen.subscriptions.all
    auth!

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @subscriptions }
    end
  end

  # GET /screens/:screen_id/fields/:field_id/subscriptions/manage
  def manage
    @subscription = Subscription.new 
    #stub out the screen ID so that CanCan can find an owner to auth
    @subscription.screen_id = @screen.id
    auth!(:actions => :create)

    @subscriptions = @screen.subscriptions.where(:field_id => @field.id)

    # Build a list of allowed feeds
    @feeds = Feed.all
    auth!(:action => :read, :object => @feeds)
    
    @fields = @screen.template.positions.collect{|p| p.field}
    @field_configs = @screen.field_configs.where(:field_id => @field.id)
    
    respond_to do |format|
      format.html # manage.html.erb
    end
  end

  # GET /screens/:screen_id/fields/:field_id/subscriptions/1
  # GET /screens/:screen_id/fields/:field_id/subscriptions/1.xml
  def show
    @subscription = Subscription.find(params[:id])
    auth!

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @subscription }
    end
  end

  # GET /screens/:screen_id/fields/:field_id/subscriptions/new
  # GET /screens/:screen_id/fields/:field_id/subscriptions/new.js
  def new
    @feed = Feed.find(params[:feed_id])

    respond_to do |format|
      format.html # show.html.erb
      format.js  { render :layout => false }
    end
  end

  # GET /screens/:screen_id/fields/:field_id/subscriptions/1/edit
  def edit
    @subscription = Subscription.find(params[:id])
    auth!
  end

  # POST /screens/:screen_id/fields/:field_id/subscriptions
  # POST /screens/:screen_id/fields/:field_id/subscriptions.xml
  def create
    @feed_ids = Array.new
		@weights = Array.new
		@errnos = Array.new
		@subscriptions = Array.new
    
		if params.has_key?("subscription_feed")
      @feed_ids = params[:subscription_feed].values
    end
		if params.has_key?("subscription_weight")
			@weights = params[:subscription_weight].values
		end

		@feed_ids.each_with_index do |feed_id, i|
			@subscriptions[i] = Subscription.new
			@subscriptions[i].screen = @screen
			@subscriptions[i].field = @field
			@subscriptions[i].feed_id = feed_id
			@subscriptions[i].weight = @weights[i]
			auth!

			@errnos[i] = !@subscriptions[i].save
      raise "error: #{ @subscriptions}"
		end


    respond_to do |format|
			@errnos.each_with_index do |errno, i|
				if errno
					format.html { render :action => "new" }
					format.xml  { render :xml => @subscriptions[i].errors, :status => :unprocessable_entity }
				end
			end
			format.html { redirect_to(manage_screen_field_subscriptions_path(@screen, @field), :notice => t('subscriptions.records_created')) }
			format.xml  { render :xml => @subscriptions, :status => :created, :location => @subscriptions }
		end
	end

  # PUT /screens/:screen_id/fields/:field_id/subscriptions/1
  # PUT /screens/:screen_id/fields/:field_id/subscriptions/1.xml
  def save_all
    #Create parallel arrays to store feeds and their weights for each subscription
    @feed_ids = Array.new
    @weights = Array.new
    @errnos = Array.new
    
    #Populate instance var with all subscription id's submitted
    if params.has_key?("subscription_id")
      @subscription_ids = params[:subscription_id].values
    end
    
    #Correspondingly populate the feed_ids array with the value of subscription 
    if params.has_key?("subscription_feed")
      @feed_ids = params[:subscription_feed].values
    end
    
    #Have the weights of those subsciptions in yet annother corresponding array
    if params.has_key?("subscription_weight")
      @weights = params[:subscription_weight].values
    end
    
    #Do some fun auth stuff before we actually do anything dangerous
    auth!   
    
    #Get a hold of all the subscriptions ID's that aren't in the form and destroy them (as the user deleted them in the form)
    @all_screen_subs = @screen.subscriptions.where(:field_id => @field.id).map(&:id)
    #Use the subtraction operator to get the difference between the arrays
    unless @subscription_ids.nil?
      @subs_to_delete = @all_screen_subs - @subscription_ids.map! { |i| i.to_i }

      unless @subs_to_delete.empty?
        #Search and destroy removed subscriptions
        @subs_to_delete.each do |d|
          Subscription.find(d).destroy
        end
      end    
    end
    
    #raise "feed_ids: #{@feed_ids}"
    if @feed_ids.empty?
      #If the feed_ids array is empty, the user has removed all the subscriptions - NUKE IT FROM ORBIT
      @screen.subscriptions.where(:field_id => @field.id).destroy_all
    else
      #Iterate through all feed ID's the user has submitted (using an iterator i)
      @feed_ids.each_with_index do |feed_id, i|
        #Check for an existing subscription corresponding the the ID the user submitted
        @this_subscription = Subscription.where(:field_id => @field.id, :feed_id => feed_id).first
        if @this_subscription.nil?
          #Create a shiny new object if we don't come up with it
          @this_subscription = Subscription.new
        end
        
        #Update attributes of all subscriptions present in form and populate array with any errors encountered
        @errnos[i] = !@this_subscription.update_attributes(:screen => @screen, :field => @field, :feed_id => feed_id, :weight => @weights[i])
      end
    end

    # update the field configuration
    results_msg = []
    if params.has_key?(:subscription)
      params[:subscription][:field_config].values.each do |attrs|
        attrs[:screen_id] = @screen.id
        attrs[:field_id] = @field.id
  
        if attrs[:_destroy] == '1' 
          if !attrs[:id].blank? # persisted record
            FieldConfig.find(attrs[:id]).destroy
          end
        elsif attrs[:id].blank?
          fc = FieldConfig.new(attrs.slice!(:id,:_destroy))
          if !fc.save
            results_msg << fc.errors.full_messages
          end
        else
          fc = FieldConfig.find(attrs[:id])
          if !fc.update_attributes(attrs.slice!(:id,:_destroy))
            results_msg << fc.errors.full_messages
          end
        end
      end  
    end  

    respond_to do |format|
      if !results_msg.empty?
        format.html { redirect_to manage_screen_field_subscriptions_path(@screen, @field), :notice => results_msg.join(", ") }
        format.xml  { render :xml => @subscriptions, :status => :unprocessable_entity }
      else
        # i dont understand this part...
        @errnos.each_with_index do |errno, i|
          if errno
            format.html { render :action => "new", :notice => "Failed to update subscriptions for this screen position" }
            format.xml  { render :xml => @subscriptions[i].errors, :status => :unprocessable_entity }
          end
        end
        format.html { redirect_to(manage_screen_field_subscriptions_path(@screen, @field), :notice => t('subscriptions.records_updated')) }
        format.xml  { render :xml => @subscriptions, :status => :created, :location => @subscriptions }
      end
    end
  end

  # DELETE /screens/:screen_id/fields/:field_id/subscriptions/1
  # DELETE /screens/:screen_id/fields/:field_id/subscriptions/1.xml
  def destroy
    @subscription = Subscription.find(params[:id])
    auth!
    @subscription.destroy

    respond_to do |format|
      format.html { redirect_to(manage_screen_field_subscriptions_url(@screen, @field)) }
      format.xml  { head :ok }
    end
  end
end

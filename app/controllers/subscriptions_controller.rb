class SubscriptionsController < ApplicationController
  before_filter :get_screen
  
  def get_screen
    @screen = Screen.find(params[:screen_id])
  end

  # GET /screen/:screen_id/subscriptions
  # GET /screen/:screen_id/subscriptions.xml
  def index
    @subscriptions = @screen.subscriptions.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @subscriptions }
    end
  end

  # GET /screen/:screen_id/subscriptions/manage
  def manage
    @this_field = Field.find(params[:field_id])
    @fields = @screen.template.positions.collect{|p| p.field}

    respond_to do |format|
      format.html # manage.html.erb
    end
  end

  # GET /screen/:screen_id/subscriptions/1
  # GET /screen/:screen_id/subscriptions/1.xml
  def show
    @subscription = Subscription.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @subscription }
    end
  end

  # GET /screen/:screen_id/subscriptions/new
  # GET /screen/:screen_id/subscriptions/new.xml
  def new
    @subscription = Subscription.new
    @subscription.screen = @screen

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @subscription }
    end
  end

  # GET /screen/:screen_id/subscriptions/1/edit
  def edit
    @subscription = Subscription.find(params[:id])
  end

  # POST /screen/:screen_id/subscriptions
  # POST /screen/:screen_id/subscriptions.xml
  def create
    @subscription = Subscription.new(params[:subscription])
    @subscription.screen = @screen

    respond_to do |format|
      if @subscription.save
        format.html { redirect_to([@screen, @subscription], :notice => t(:subscription_created)) }
        format.xml  { render :xml => @subscription, :status => :created, :location => @subscription }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @subscription.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /screen/:screen_id/subscriptions/1
  # PUT /screen/:screen_id/subscriptions/1.xml
  def update
    @subscription = Subscription.find(params[:id])

    respond_to do |format|
      if @subscription.update_attributes(params[:subscription])
        format.html { redirect_to([@screen, @subscription], :notice => t(:subscription_updated)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @subscription.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /screen/:screen_id/subscriptions/1
  # DELETE /screen/:screen_id/subscriptions/1.xml
  def destroy
    @subscription = Subscription.find(params[:id])
    @subscription.destroy

    respond_to do |format|
      format.html { redirect_to(screen_subscriptions_url(@screen)) }
      format.xml  { head :ok }
    end
  end
end

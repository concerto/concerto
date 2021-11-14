class SubscriptionsController < ApplicationController
  before_action :get_screen, :get_field
  
  def get_screen
    @screen = Screen.find(params[:screen_id])
  end

  def get_field
    @field = Field.find(params[:field_id])
  end

  # GET /screens/:screen_id/fields/:field_id/subscriptions
  # GET /screens/:screen_id/fields/:field_id/subscriptions.xml
  def index
    @subscriptions = @screen.subscriptions.where(field_id: @field.id)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @subscriptions }
    end
  end

  # GET /screens/:screen_id/fields/:field_id/subscriptions/1
  # GET /screens/:screen_id/fields/:field_id/subscriptions/1.xml
  def show
    @subscription = Subscription.find(params[:id])
    auth!

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @subscription }
    end
  end

  # GET /screens/:screen_id/fields/:field_id/subscriptions/new
  # GET /screens/:screen_id/fields/:field_id/subscriptions/new.js
  def new
    if params[:feed_id]
      @feed = Feed.find(params[:feed_id])
    else
      @subscriptions = @screen.subscriptions.where(field_id: @field.id)
    end

    respond_to do |format|
      format.html # show.html.erb
      format.js
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
    @subscription = Subscription.new(subscription_params)
    @subscription.screen = @screen
    @subscription.field = @field
    auth!

    # Verify the screen can read the feed
    ability = Ability.new(@screen)
    @subscription.feed = nil if ability.cannot?(:read, @subscription.feed)

    respond_to do |format|
      if @subscription.save
        format.html { redirect_to(screen_field_subscriptions_path(@screen, @field), notice: t(:subscription_created)) }
        format.xml  { render xml: @subscription, status: :created, location: @subscription }
        format.js
      else
        format.html { render action: "new" }
        format.xml  { render xml: @subscription.errors, status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @subscription = Subscription.find(params[:id])
    auth!

    respond_to do |format|
      if @subscription.update_attributes(subscription_params)
        format.html { redirect_to(screen_field_subscriptions_path(@screen, @field), notice: t('subscriptions.records_updated')) }
        format.xml  { head :ok }
        format.js { head :ok }
      else
        format.html { redirect_to(screen_field_subscriptions_path(@screen, @field)) }
        format.xml  { render xml: @subscription.errors, status: :unprocessable_entity }
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
      format.html { redirect_to(screen_field_subscription_path(@screen, @field)) }
      format.xml  { head :ok }
      format.js { head :ok }
    end
  end

  private
  def subscription_params
    params.require(:subscription).permit(:feed_id, :weight)
  end

end

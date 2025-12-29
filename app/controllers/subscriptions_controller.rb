class SubscriptionsController < ApplicationController
  before_action :authenticate_user!, except: [ :index ]
  before_action :set_screen
  before_action :set_subscription, only: %i[ update destroy ]

  # Ensure that Pundit authorization has been performed for every action.
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  # GET /subscriptions or /subscriptions.json
  def index
    @subscriptions = policy_scope(@screen.subscriptions).includes(:feed, :field)

    # Initialize the hash to avoid nil errors
    @available_feeds_by_field = {}

    # Check if screen has template and positions
    if @screen.template && @screen.template.positions.any?
      field_ids = @screen.template.positions.pluck(:field_id)

      # Get all subscribed feed IDs for these fields in one query
      subscribed_feeds = @screen.subscriptions.where(field_id: field_ids).pluck(:field_id, :feed_id)
      subscribed_by_field = subscribed_feeds.group_by(&:first).transform_values { |pairs| pairs.map(&:second) }

      all_feeds = Feed.all.to_a

      field_ids.each do |field_id|
        subscribed_feed_ids = subscribed_by_field[field_id] || []
        @available_feeds_by_field[field_id] = all_feeds.reject { |feed| subscribed_feed_ids.include?(feed.id) }
      end
    end

    # Ensure all existing subscriptions have entries (for inactive subscriptions display)
    @subscriptions.pluck(:field_id).uniq.each do |field_id|
      @available_feeds_by_field[field_id] ||= Feed.none
    end
  end

  # POST /subscriptions or /subscriptions.json
  def create
    @subscription = @screen.subscriptions.build(subscription_params)

    authorize @subscription

    respond_to do |format|
      if @subscription.save
        format.html { redirect_to screen_subscriptions_url(@screen), notice: "#{@subscription.field.name} field subscription to #{@subscription.feed.name} feed was successfully created." }
        format.json { render :show, status: :created, location: @subscription }
      else
        error_message = @subscription.errors.full_messages.join(", ")
        format.html { redirect_to screen_subscriptions_url(@screen), alert: "Failed to create subscription: #{error_message}" }
        format.json { render json: @subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /subscriptions/1 or /subscriptions/1.json
  def update
    authorize @subscription

    respond_to do |format|
      if @subscription.update(subscription_params)
        format.html { redirect_to screen_subscriptions_url(@screen), notice: "Subscription weight was successfully updated." }
        format.json { render :show, status: :ok, location: @subscription }
      else
        error_message = @subscription.errors.full_messages.join(", ")
        format.html { redirect_to screen_subscriptions_url(@screen), alert: "Failed to update subscription: #{error_message}" }
        format.json { render json: @subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subscriptions/1 or /subscriptions/1.json
  def destroy
    authorize @subscription

    @subscription.destroy!

    respond_to do |format|
      format.html { redirect_to screen_subscriptions_url(@screen), notice: "#{@subscription.field.name} field subscription to #{@subscription.feed.name} feed was successfully removed." }
      format.json { head :no_content }
    end
  end

  private
    # Subscription URLs are always nested under a screen.
    def set_screen
      @screen = Screen.find(params[:screen_id])
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def subscription_params
      params.require(:subscription).permit(:field_id, :feed_id, :weight)
    end
end

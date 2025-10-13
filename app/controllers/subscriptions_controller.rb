class SubscriptionsController < ApplicationController
  before_action :set_screen
  before_action :set_subscription, only: %i[ destroy ]

  # GET /subscriptions or /subscriptions.json
  def index
    @subscriptions = @screen.subscriptions.includes(:feed)
    @available_feeds_by_field = {}
    @screen.template.positions.each do |position|
      @available_feeds_by_field[position.field_id] = available_feeds_for_field(position.field_id)
    end
  end

  # POST /subscriptions or /subscriptions.json
  def create
    @subscription = Subscription.new(subscription_params)
    @subscription.screen = @screen

    respond_to do |format|
      if @subscription.save
        format.html { redirect_to screen_subscriptions_url(@screen), notice: "#{@subscription.field.name} field subscription to #{@subscription.feed.name} feed was successfully created." }
        format.json { render :show, status: :created, location: @subscription }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subscriptions/1 or /subscriptions/1.json
  def destroy
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
      params.require(:subscription).permit(:field_id, :feed_id)
    end

    # Get feeds that are not already subscribed to for a specific field
    def available_feeds_for_field(field_id)
      # Get IDs of feeds already subscribed to this field on this screen
      subscribed_feed_ids = @screen.subscriptions.where(field_id: field_id).pluck(:feed_id)

      # Return feeds that are not in the subscribed list
      if subscribed_feed_ids.any?
        Feed.where.not(id: subscribed_feed_ids)
      else
        Feed.all
      end
    end
end

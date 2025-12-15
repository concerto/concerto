class RssFeedsController < ApplicationController
  before_action :set_rss_feed, only: %i[ show edit update destroy refresh cleanup ]
  before_action :set_form_options, only: %i[ new edit create update ]

  after_action :verify_authorized

  # GET /rss_feeds/1 or /rss_feeds/1.json
  def show
    authorize @rss_feed
  end

  # GET /rss_feeds/new
  def new
    @rss_feed = RssFeed.new(formatter: :headlines)
    authorize @rss_feed
  end

  # GET /rss_feeds/1/edit
  def edit
    authorize @rss_feed
  end

  # POST /rss_feeds or /rss_feeds.json
  def create
    @rss_feed = RssFeed.new(rss_feed_params)

    authorize @rss_feed

    respond_to do |format|
      if @rss_feed.save
        format.html { redirect_to rss_feed_url(@rss_feed), notice: "RSS Feed was successfully created." }
        format.json { render :show, status: :created, location: @rss_feed }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @rss_feed.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /rss_feeds/1 or /rss_feeds/1.json
  def update
    @rss_feed.assign_attributes(rss_feed_params)

    authorize @rss_feed

    respond_to do |format|
      if @rss_feed.save
        format.html { redirect_to rss_feed_url(@rss_feed), notice: "RSS Feed was successfully updated." }
        format.json { render :show, status: :ok, location: @rss_feed }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @rss_feed.errors, status: :unprocessable_entity }
      end
    end
  end

  def refresh
    authorize @rss_feed
    @rss_feed.refresh
    redirect_to rss_feed_url(@rss_feed), notice: "RSS Feed was refreshed."
  end

  def cleanup
    authorize @rss_feed
    destroyed = @rss_feed.cleanup_unused_content
    redirect_to rss_feed_url(@rss_feed), notice: "Cleaned up #{destroyed.length} unused pieces of content."
  end

  # DELETE /rss_feeds/1 or /rss_feeds/1.json
  def destroy
    authorize @rss_feed
    @rss_feed.destroy!

    respond_to do |format|
      format.html { redirect_to feeds_url, notice: "RSS Feed was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_rss_feed
      @rss_feed = RssFeed.find(params[:id])
    end

    # Sets options for form selects.
    def set_form_options
      if current_user.system_admin?
        @groups = Group.all
      else
        # In an edit context, ensure the feed's current group is in the list for display,
        # even if the user is not an admin of it. They won't be able to *switch* to it,
        # but they should be able to see it.
        @groups = if @rss_feed&.persisted?
          (current_user.admin_groups + [ @rss_feed.group ]).compact.uniq
        else
          current_user.admin_groups
        end
      end
    end

    # Only allow a list of trusted parameters through.
    def rss_feed_params
      params.require(:rss_feed).permit(policy(@rss_feed || RssFeed.new).permitted_attributes + [ :url, :formatter ])
    end
end

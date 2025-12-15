class FeedsController < ApplicationController
  before_action :set_feed, only: %i[ show edit update destroy ]
  before_action :set_form_options, only: %i[ new edit create update ]

  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  # GET /feeds or /feeds.json
  def index
    @feeds = policy_scope(Feed)
  end

  # GET /feeds/1 or /feeds/1.json
  def show
    authorize @feed
  end

  # GET /feeds/new
  def new
    @feed = Feed.new
    authorize @feed
  end

  # GET /feeds/1/edit
  def edit
    authorize @feed
  end

  # POST /feeds or /feeds.json
  def create
    @feed = Feed.new(feed_params)

    authorize @feed

    respond_to do |format|
      if @feed.save
        format.html { redirect_to feed_url(@feed), notice: "Feed was successfully created." }
        format.json { render :show, status: :created, location: @feed }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @feed.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /feeds/1 or /feeds/1.json
  def update
    @feed.assign_attributes(feed_params)

    authorize @feed

    respond_to do |format|
      if @feed.save
        format.html { redirect_to feed_url(@feed), notice: "Feed was successfully updated." }
        format.json { render :show, status: :ok, location: @feed }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @feed.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /feeds/1 or /feeds/1.json
  def destroy
    authorize @feed

    @feed.destroy!

    respond_to do |format|
      format.html { redirect_to feeds_url, notice: "Feed was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_feed
      @feed = Feed.find(params[:id])
    end

    # Sets options for form selects.
    def set_form_options
      if current_user.system_admin?
        @groups = Group.all
      else
        # In an edit context, ensure the feed's current group is in the list for display,
        # even if the user is not an admin of it. They won't be able to *switch* to it,
        # but they should be able to see it.
        @groups = if @feed&.persisted?
          (current_user.admin_groups + [ @feed.group ]).compact.uniq
        else
          current_user.admin_groups
        end
      end
    end

    # Only allow a list of trusted parameters through.
    def feed_params
      params.require(:feed).permit(policy(@feed || Feed.new).permitted_attributes)
    end
end

class FeedsController < ApplicationController
  before_action :set_feed, only: %i[ show edit update destroy ]
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
    authorize @feed

    respond_to do |format|
      if @feed.update(feed_params)
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

    # Only allow a list of trusted parameters through.
    def feed_params
      params.require(:feed).permit(policy(@feed || Feed.new).permitted_attributes)
    end
end

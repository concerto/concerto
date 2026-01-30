class RemoteFeedsController < ApplicationController
  before_action :set_remote_feed, only: %i[ show edit update destroy refresh ]
  before_action :set_form_options, only: %i[ new edit create update ]

  after_action :verify_authorized

  def show
    authorize @remote_feed
  end

  def new
    @remote_feed = RemoteFeed.new
    authorize @remote_feed
  end

  def edit
    authorize @remote_feed
  end

  def create
    @remote_feed = RemoteFeed.new(remote_feed_params)

    authorize @remote_feed

    respond_to do |format|
      if @remote_feed.save
        format.html { redirect_to remote_feed_url(@remote_feed), notice: "Remote Feed was successfully created." }
        format.json { render :show, status: :created, location: @remote_feed }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @remote_feed.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @remote_feed.assign_attributes(remote_feed_params)

    authorize @remote_feed

    respond_to do |format|
      if @remote_feed.save
        format.html { redirect_to remote_feed_url(@remote_feed), notice: "Remote Feed was successfully updated." }
        format.json { render :show, status: :ok, location: @remote_feed }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @remote_feed.errors, status: :unprocessable_entity }
      end
    end
  end

  def refresh
    authorize @remote_feed
    @remote_feed.refresh
    redirect_to remote_feed_url(@remote_feed), notice: "Remote Feed was refreshed."
  end

  def destroy
    authorize @remote_feed
    @remote_feed.destroy!

    respond_to do |format|
      format.html { redirect_to feeds_url, notice: "Remote Feed was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private
    def set_remote_feed
      @remote_feed = RemoteFeed.find(params[:id])
    end

    def set_form_options
      if current_user.system_admin?
        @groups = Group.all
      else
        @groups = (current_user.admin_groups + [ @remote_feed&.group ]).compact.uniq.sort_by(&:name)
      end
    end

    def remote_feed_params
      params.require(:remote_feed).permit(policy(@remote_feed || RemoteFeed.new).permitted_attributes + [ :url ])
    end
end

class VideosController < ApplicationController
  include ContentUploadable

  before_action :authenticate_user!, except: %i[show]
  before_action :set_video, only: %i[show edit update destroy]
  after_action :verify_authorized

  # GET /videos/1 or /videos/1.json
  def show
    authorize @video
  end

  # GET /videos/new
  def new
    @video = Video.new
    authorize @video
  end

  # GET /videos/1/edit
  def edit
    authorize @video
  end

  # POST /videos or /videos.json
  def create
    @video = Video.new(video_params)
    @video.user = current_user

    authorize @video

    respond_to do |format|
      if @video.save
        format.html { redirect_to video_url(@video), notice: "Video was successfully created." }
        format.json { render :show, status: :created, location: @video }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @video.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /videos/1 or /videos/1.json
  def update
    authorize @video

    respond_to do |format|
      if @video.update(video_params)
        format.html { redirect_to video_url(@video), notice: "Video was successfully updated." }
        format.json { render :show, status: :ok, location: @video }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @video.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /videos/1 or /videos/1.json
  def destroy
    authorize @video

    @video.destroy!

    respond_to do |format|
      format.html { redirect_to contents_path, status: :see_other, notice: "Video was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_video
      @video = Video.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def video_params
      params.expect(video: policy(@video || Video.new).permitted_attributes + [ :url ])
    end
end

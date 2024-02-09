class TextBlobsController < ApplicationController
  before_action :set_text_blob, only: %i[ show edit update destroy ]

  # GET /text_blobs or /text_blobs.json
  def index
    @text_blobs = TextBlob.all
  end

  # GET /text_blobs/1 or /text_blobs/1.json
  def show
  end

  # GET /text_blobs/new
  def new
    @text_blob = TextBlob.new(content: Content.new)
  end

  # GET /text_blobs/1/edit
  def edit
  end

  # POST /text_blobs or /text_blobs.json
  def create
    @text_blob = TextBlob.new(text_blob_params)

    respond_to do |format|
      if @text_blob.save
        format.html { redirect_to text_blob_url(@text_blob), notice: "Text blob was successfully created." }
        format.json { render :show, status: :created, location: @text_blob }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @text_blob.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /text_blobs/1 or /text_blobs/1.json
  def update
    respond_to do |format|
      if @text_blob.update(text_blob_params)
        format.html { redirect_to text_blob_url(@text_blob), notice: "Text blob was successfully updated." }
        format.json { render :show, status: :ok, location: @text_blob }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @text_blob.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /text_blobs/1 or /text_blobs/1.json
  def destroy
    @text_blob.destroy!

    respond_to do |format|
      format.html { redirect_to text_blobs_url, notice: "Text blob was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_text_blob
      @text_blob = TextBlob.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def text_blob_params
      params[:text_blob][:render_as] = params[:text_blob][:render_as].to_i

      params.require(:text_blob).permit(:body, :render_as, content_attributes: ContentsController::ContentParams)
    end
end

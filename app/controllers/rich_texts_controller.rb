class RichTextsController < ApplicationController
  before_action :set_rich_text, only: %i[ show edit update destroy ]

  # GET /rich_texts or /rich_texts.json
  def index
    @rich_texts = RichText.all
  end

  # GET /rich_texts/1 or /rich_texts/1.json
  def show
  end

  # GET /rich_texts/new
  def new
    @rich_text = RichText.new
  end

  # GET /rich_texts/1/edit
  def edit
  end

  # POST /rich_texts or /rich_texts.json
  def create
    @rich_text = RichText.new(rich_text_params)

    respond_to do |format|
      if @rich_text.save
        format.html { redirect_to rich_text_url(@rich_text), notice: "Rich text was successfully created." }
        format.json { render :show, status: :created, location: @rich_text }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @rich_text.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /rich_texts/1 or /rich_texts/1.json
  def update
    respond_to do |format|
      if @rich_text.update(rich_text_params)
        format.html { redirect_to rich_text_url(@rich_text), notice: "Rich text was successfully updated." }
        format.json { render :show, status: :ok, location: @rich_text }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @rich_text.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /rich_texts/1 or /rich_texts/1.json
  def destroy
    @rich_text.destroy!

    respond_to do |format|
      format.html { redirect_to rich_texts_url, notice: "Rich text was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_rich_text
      @rich_text = RichText.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def rich_text_params
      params.require(:rich_text).permit(:name, :duration, :start_time, :end_time, :text, :render_as)
    end
end

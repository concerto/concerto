class GraphicsController < ApplicationController
  include ContentUploadable

  before_action :authenticate_user!, except: %i[show]
  before_action :set_graphic, only: %i[show edit update destroy]
  after_action :verify_authorized

  # GET /graphics/1 or /graphics/1.json
  def show
    authorize @graphic

    if @graphic.image.attached? && !@graphic.image.analyzed?
      @graphic.image.analyze_later()
      flash[:alert] = "This graphic is queued for re-processing."
    end
  end

  # GET /graphics/new
  def new
    @graphic = Graphic.new
    authorize @graphic
  end

  # GET /graphics/1/edit
  def edit
    authorize @graphic
  end

  # POST /graphics or /graphics.json
  def create
    @graphic = Graphic.new(graphic_params)
    @graphic.user = current_user

    authorize @graphic

    respond_to do |format|
      if @graphic.save
        format.html { redirect_to graphic_url(@graphic), notice: "Graphic was successfully created." }
        format.json { render :show, status: :created, location: @graphic }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @graphic.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /graphics/1 or /graphics/1.json
  def update
    authorize @graphic

    respond_to do |format|
      if @graphic.update(graphic_params)
        format.html { redirect_to graphic_url(@graphic), notice: "Graphic was successfully updated." }
        format.json { render :show, status: :ok, location: @graphic }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @graphic.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /graphics/1 or /graphics/1.json
  def destroy
    authorize @graphic

    @graphic.destroy!

    respond_to do |format|
      format.html { redirect_to contents_url, notice: "Graphic was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_graphic
      @graphic = Graphic.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def graphic_params
      params.require(:graphic).permit(policy(@graphic || Graphic.new).permitted_attributes + [ :image ])
    end
end

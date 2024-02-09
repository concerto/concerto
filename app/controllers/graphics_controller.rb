class GraphicsController < ApplicationController
  before_action :set_graphic, only: %i[ show edit update destroy ]

  # GET /graphics or /graphics.json
  def index
    @graphics = Graphic.all
  end

  # GET /graphics/1 or /graphics/1.json
  def show
  end

  # GET /graphics/new
  def new
    @graphic = Graphic.new(content: Content.new)
  end

  # GET /graphics/1/edit
  def edit
  end

  # POST /graphics or /graphics.json
  def create
    @graphic = Graphic.new(graphic_params)

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
    @graphic.destroy!

    respond_to do |format|
      format.html { redirect_to graphics_url, notice: "Graphic was successfully destroyed." }
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
      params.require(:graphic).permit(:image, content_attributes: [ :id, :name, :duration, :start_time, :end_time ])
    end
end

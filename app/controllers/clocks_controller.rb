class ClocksController < ApplicationController
  include ContentUploadable

  before_action :authenticate_user!, except: %i[show]
  before_action :set_clock, only: %i[show edit update destroy]
  after_action :verify_authorized

  # GET /clocks/1 or /clocks/1.json
  def show
    authorize @clock
  end

  # GET /clocks/new
  def new
    @clock = Clock.new(format: Clock.formats[:time_12h])
    authorize @clock
  end

  # GET /clocks/1/edit
  def edit
    authorize @clock
  end

  # POST /clocks or /clocks.json
  def create
    @clock = Clock.new(clock_params)
    @clock.user = current_user

    authorize @clock

    respond_to do |format|
      if @clock.save
        format.html { redirect_to clock_url(@clock), notice: "Clock was successfully created." }
        format.json { render :show, status: :created, location: @clock }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @clock.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /clocks/1 or /clocks/1.json
  def update
    authorize @clock

    respond_to do |format|
      if @clock.update(clock_params)
        format.html { redirect_to clock_url(@clock), notice: "Clock was successfully updated." }
        format.json { render :show, status: :ok, location: @clock }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @clock.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /clocks/1 or /clocks/1.json
  def destroy
    authorize @clock

    @clock.destroy!

    respond_to do |format|
      format.html { redirect_to contents_url, notice: "Clock was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_clock
      @clock = Clock.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def clock_params
      params.require(:clock).permit(policy(@clock || Clock.new).permitted_attributes + [ :format ])
    end
end

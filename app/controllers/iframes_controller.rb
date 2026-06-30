class IframesController < ApplicationController
  include ContentUploadable

  before_action :authenticate_user!, except: %i[show]
  before_action :set_iframe, only: %i[show edit update destroy]
  after_action :verify_authorized

  # GET /iframes/1 or /iframes/1.json
  def show
    authorize @iframe
  end

  # GET /iframes/new
  def new
    @iframe = Iframe.new
    authorize @iframe
  end

  # GET /iframes/1/edit
  def edit
    authorize @iframe
  end

  # POST /iframes or /iframes.json
  def create
    @iframe = Iframe.new(iframe_params)
    @iframe.user = current_user

    authorize @iframe

    respond_to do |format|
      if @iframe.save
        format.html { redirect_to iframe_url(@iframe), notice: "Web page was successfully created." }
        format.json { render :show, status: :created, location: @iframe }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @iframe.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /iframes/1 or /iframes/1.json
  def update
    authorize @iframe

    respond_to do |format|
      if @iframe.update(iframe_params)
        format.html { redirect_to iframe_url(@iframe), notice: "Web page was successfully updated." }
        format.json { render :show, status: :ok, location: @iframe }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @iframe.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /iframes/1 or /iframes/1.json
  def destroy
    authorize @iframe

    @iframe.destroy!

    respond_to do |format|
      format.html { redirect_to contents_path, status: :see_other, notice: "Web page was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_iframe
      @iframe = Iframe.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def iframe_params
      params.expect(iframe: policy(@iframe || Iframe.new).permitted_attributes + [ :url ])
    end
end

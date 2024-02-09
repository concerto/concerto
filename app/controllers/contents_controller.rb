class ContentsController < ApplicationController
  before_action :set_content, only: %i[ show destroy ]

  # GET /contents or /contents.json
  def index
    @contents = Content.all
  end

  # GET /contents/1 or /contents/1.json
  def show
  end

  # DELETE /contents/1 or /contents/1.json
  def destroy
    @content.destroy!

    respond_to do |format|
      format.html { redirect_to contents_url, notice: "Content was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_content
      @content = Content.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def content_params
      params.require(:content).permit(:name, :duration, :start_time, :end_time, :subtype_id, :subtype_type)
    end
end

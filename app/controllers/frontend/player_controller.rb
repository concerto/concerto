class Frontend::PlayerController < ApplicationController
  before_action :set_screen, only: %i[ show ]

  # GET /frontend/1
  def show
    render layout: false
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_screen
    @screen = Screen.find(params[:id])
  end
end

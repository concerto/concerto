class Frontend::PwaController < Frontend::ApplicationController
  before_action :set_screen

  def manifest
    render template: "frontend/pwa/manifest", layout: false
  end

  private
  def set_screen
    @screen = Screen.find(params[:screen_id])
  end
end

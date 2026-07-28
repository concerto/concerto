class Frontend::PlayerController < ActionController::Base
  # The player supports older browsers which are compatible with its features.
  # This should be kept in-sync with vite.config.ts's plugin-legacy targets:
  # the chrome floor matches the legacy `targets`, the rest match `modernTargets`.
  # Chrome 53 covers older LG WebOS signage screens (see issue #1927), served the
  # SystemJS legacy bundle since they lack native ES modules.
  allow_browser versions: { chrome: 53, firefox: 69, safari: 13.1, opera: 51, ie: false }, block: -> {
    render "frontend/player/unacceptable_browser", status: :not_acceptable, layout: false
  }

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

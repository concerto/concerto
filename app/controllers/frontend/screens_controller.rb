class Frontend::ScreensController < Frontend::ApplicationController
  before_action :set_screen, only: %i[ show ]

  def show
    positions = @screen.template.positions.map { |p|
      {
        top: p.top,
        left: p.left,
        bottom: p.bottom,
        right: p.right,
        style: p.style,
        content_uri: frontend_content_path(screen_id: @screen.id, field_id: p.field_id, format: :json)
      }
    }

    render json: {
      template: {
        background_uri: url_for(@screen.template.image)
      },
      positions: positions
    }
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_screen
    @screen = Screen.find(params[:id])
  end
end

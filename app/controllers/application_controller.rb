# Note: This controller is not used for the frontend.
# See frontend/application_controller.

class ApplicationController < ActionController::Base
  include DeviseAllowlist
  include Pundit::Authorization
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private
  def user_not_authorized
    respond_to do |format|
      format.html do
        flash[:alert] = "You are not authorized to perform this action."
        redirect_to(request.referrer || root_path)
      end
      format.json { render json: { error: "Not authorized" }, status: :forbidden }
    end
  end
end

class ErrorsController < ApplicationController

  # This method handles all routes that the router cannot find a home for.
  # It does not handle 404 errors that are triggered after a route has been found
  # like the ones thrown in a controller.
  # GET /route_not_defined.
  def error_404
    respond_to do |format|
      format.html { render :template => "errors/error_404", :layout => "layouts/application", :status => 404 }
      format.any { render :nothing => true, :status => 404 }
    end
  end
end

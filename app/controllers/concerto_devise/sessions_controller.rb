#Overriding the Devise Sessions controller for fun and profit
class ConcertoDevise::SessionsController < Devise::SessionsController

  # GET /resource/sign_in
  def new
    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)

    # if :no_content_cell param is set to true, do not render the layout or the content cell container within the view
    if params[:no_content_cell]
      respond_with(resource, serialize_options(resource)) do |format|
        format.html { render :layout => false }
      end
    else
      respond_with(resource, serialize_options(resource))
    end
  end
end

class ErrorsController < ApplicationController
  # This action is not intended for normal routing.
  #
  # Instead, it is called when an exception occurs and is caught by the Rails
  # ShowErrors middleware. It is sent to this action due to configuration in
  # config/application.rb.
  def render_error
    # The route requested contains the status code, /404, /500, /etc.
    # If we wound up here,
    @status_code = env["PATH_INFO"][1..-1]
    #@exception = env["action_dispatch.exception"]
    #@status_code = ActionDispatch::ExceptionWrapper.new(env, @exception).status_code

    if @status_code == "404"
      template = :error_404
      layout = true # Default application layout
    else
      template = :error_generic
      layout = 'no-topmenu'
    end

    begin
      status_text = 'HTTP ' + @status_code + '/' +
        Rack::Utils::HTTP_STATUS_CODES[@status_code.to_i]
    rescue
      status_text = t(:unknown_error)
    end

    respond_to do |format|
      format.html { render template, status: @status_code, layout: layout}
      format.json { render text: status_text, status: @status_code }
      format.xml  { render xml: {error: status_text}, status: @status_code }
      format.any { render text: status_text, status: @status_code }
    end
  end
end

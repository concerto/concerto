class MediaController < ApplicationController
  skip_before_filter :verify_authenticity_token,  :only => [:create]

  # GET /media/1
  def show
    # TODO this needs to be secured
    @media = Media.find(params[:id])
    send_data @media.file_contents, :filename => @media.file_name, :type => @media.file_type, :disposition => 'inline'
  end

  # POST /media
  # Save the graphics that we are going to preview as media without a corresponding graphic model
  # and return the id so we can use it for the preview process.  
  # This is ajax posted from the graphic form.
  def create
    auth!(:object => Media, :action => :create)
    @media = Media.new(:file => media_params[:graphic][:media_attributes]["0"][:file])
    @media.attachable_id = 0  # this is assigned to the actual Graphic record when the graphic is saved
    @media.attachable_type = 'Content'
    @media.key = 'preview'
    if @media.save
      # jquery.iframe-transport requires result sent back in textarea
      render :inline  => "<textarea data-type='application/json'>#{@media.to_json(:only => :id)}</textarea>" 
    else
      raise 'Problem saving media ' + @media.errors.full_messages.join("; ")
    end
  end

  def media_params
    params.permit(:graphic => [ :media_attributes => [ :file, :key ] ])
  end
end

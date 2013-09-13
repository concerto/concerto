class MediaController < ApplicationController
  # GET /media/1
  def show
    @media = Media.find(params[:id])
    send_data @media.file_contents, :filename => @media.file_name, :type => @media.file_type, :disposition => 'inline'
  end

  # POST /media
  # be able to save the graphics that we are going to preview
  # and return the id so we can use it
  def create
    @media = Media.new(:file => media_params[:graphic][:media_attributes]["0"][:file])
    @media.attachable_id = 0
    @media.attachable_type = 'Preview'
    @media.key = 'Preview'  # use guid to send back to client
    if @media.save
      respond_to do |format|
        format.html { render :inline  => "<textarea data-type='application/json'>#{@media.to_json(:except => :file_data)}</textarea>" }
        format.json { render :json => @media.to_json }
      end
    else
      raise 'Problem saving media ' + @media.errors.full_messages.join("; ")
    end
  end

  def media_params
    params.permit(:graphic => [ :media_attributes => [ :file, :key ] ])
  end
end

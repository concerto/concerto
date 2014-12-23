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

    @medias = []
    files = get_file_params
    files.each do |file|

      media = Media.new(:file => file)

      if media.file_size > 0 && Concerto::ContentConverter.supported_types.include?(media.file_type)
        converted_medias = Concerto::ContentConverter.convert([media])
        media = converted_medias.select{ |m| m.key == 'processed' }.first
      end

      media.attachable_id = 0  # this is assigned to the actual Graphic record when the graphic is saved
      media.attachable_type = 'Content'
      media.key = 'preview'

      media.save
      @medias << media
    end
    json = @medias.to_json(:only => :id)
    # jquery.iframe-transport requires result sent back in textarea
    if params['X-Requested-With'] == 'IFrame'
      render :inline  => "<textarea data-type='application/json'>#{json}</textarea>"
    else
      render :json => json
    end
  end

  private

  def get_file_params(h = params.permit!.to_hash)
    files = []
    h.each do |k,v|
      value = v || k
      if value.is_a?(Hash) || value.is_a?(Array)
        files += get_file_params(value)
      else
        files << k if k && k.is_a?(ActionDispatch::Http::UploadedFile)
        files << v if v && v.is_a?(ActionDispatch::Http::UploadedFile)
      end
    end
    files
  end
end

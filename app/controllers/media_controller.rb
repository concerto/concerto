class MediaController < ApplicationController
  include ActionView::Helpers::NumberHelper

  skip_before_filter :verify_authenticity_token,  only: [:create]

  # GET /media/1
  def show
    # TODO this needs to be secured
    @media = Media.find(params[:id])
    send_data @media.file_contents, filename: @media.file_name, type: @media.file_type, disposition: 'inline'
  end

  # POST /media
  # Save the graphics that we are going to preview as media without a corresponding graphic model
  # and return the id so we can use it for the preview process.  
  # This is ajax posted from the graphic form.
  def create
    require 'concerto_image_magick'
    auth!(object: Media, action: :create)

    @medias = []
    files = get_file_params
    image_info = nil # We will use this to store resolution etc.
    files.each do |file|

      media = Media.new(file: file)
      if media.file_size > 0 && Concerto::ContentConverter.supported_types.include?(media.file_type)
        converted_medias = Concerto::ContentConverter.convert([media])
        media = converted_medias.select{ |m| m.key == 'processed' }.first
      elsif media.file_size > 0 && media.file_type == 'image/jpeg'
        # if it's a photo then auto orient it
        adjusted_image = ConcertoImageMagick.load_image(media.file_contents)
        unless adjusted_image.blank?
          adjusted_image.auto_orient!

          media.file_data = adjusted_image.to_blob
          media.file_size = adjusted_image.filesize
        end
      end

      adjusted_image ||= ConcertoImageMagick.load_image(media.file_contents)
      image_info = ConcertoImageMagick.image_info(adjusted_image)

      media.attachable_id = 0  # this is assigned to the actual Graphic record when the graphic is saved
      media.attachable_type = 'Content'
      media.key = 'preview'

      media.save
      @medias << media
    end
    results = @medias.map {|m| {id: m.id}}
    results.first[:info] = "#{number_to_human_size(image_info[:size])}, #{image_info[:width]}x#{image_info[:height]}" if !image_info.blank?
    results_json = results.to_json 
    # jquery.iframe-transport requires result sent back in textarea
    if params['X-Requested-With'] == 'IFrame'
      render inline: "<textarea data-type='application/json'>#{results_json}</textarea>"
    else
      render json: results_json
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

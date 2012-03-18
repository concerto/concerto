class Frontend::TemplatesController < ApplicationController

  # GET /frontend/1/template/1
  # Render the template for display on a screen.
  def show
    template = Template.find(params[:id])
    if stale?(:last_modified => template.last_modified.utc, :etag => template, :public => true)
      require'image_utility'
      media = template.media.original.first
      image = Magick::Image.from_blob(media.file_contents).first

      # Resize the image to a height and width if they are both being set.
      # Round these numbers up to ensure the image will at least fill
      # the requested space.
      height = params[:height].nil? ? nil : params[:height].to_f.ceil
      width = params[:width].nil? ? nil : params[:width].to_f.ceil 

      image = ImageUtility.resize(image, width, height, false)
      case request.format
        when Mime::Type.lookup_by_extension(:jpg)
          image.format = "JPG"
        when Mime::PNG
          image.format = "PNG"
        else
          render :status => 406, :text => "Unacceptable image type." and return
      end

      send_data image.to_blob,
                :filename => "#{template.name.underscore}.#{image.format.downcase}",
                :type => image.mime_type, :disposition => 'inline'
    end
  end

end

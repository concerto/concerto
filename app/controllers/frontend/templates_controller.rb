class Frontend::TemplatesController < ApplicationController

  # GET /frontend/1/template/1
  # Render the template for display on a screen.
  def show
    template = Template.find(params[:id])
    if stale?(:last_modified => template.last_modified.utc, :etag => template, :public => true)     
      require 'concerto_image_magick'
      image = ConcertoImageMagick.load_image(template.media.original.first.file_contents)

      # Resize the image to a height and width if they are both being set.
      image = ConcertoImageMagick.graphic_transform(image, :width => params[:width], :height => params[:height], :crop => false)
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

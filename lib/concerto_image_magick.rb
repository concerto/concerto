#ImageMagick-specfic image manipulation calls for Concerto 2
module ConcertoImageMagick

  def self.load_image(file_contents)
    return Magick::Image.from_blob(file_contents).first
  end
  
  def self.new_drawing_object
    return Magick::Draw.new
  end
  
  def self.draw_image(dw,image)
    dw.draw(image)
  end
  
  def self.draw_block(dw, options={})
    #Draw the rectangle
    dw.fill(options[:fill_color])
    dw.stroke_opacity(options[:stroke_opacity])
    dw.fill_opacity(options[:fill_opacity])
    dw.rectangle(options[:width]*options[:left], options[:height]*options[:top], options[:width]*options[:right], options[:height]*options[:bottom])
  end
 
  def self.draw_text(dw, options={})
    #Layer the field name
    dw.stroke(options[:stroke_color])
    dw.fill(options[:fill_color])
    dw.text_anchor(Magick::MiddleAnchor)
    dw.opacity(options[:opacity])
    font_size = [options[:width], options[:height]].min / 8
    dw.pointsize = font_size
    dw.text((options[:width]*(options[:left] + options[:right])/2),
            (options[:height]*(options[:top] + options[:bottom])/2+0.4*font_size),
            options[:field_name])  
  end

  def self.graphic_transform(original_media, options={})
    image = load_image(original_media.file_contents)

    # Resize the image to a height and width if they are both being set.
    # Round these numbers up to ensure the image will at least fill
    # the requested space.
    height = options[:height].nil? ? nil : options[:height].to_f.ceil
    width = options[:width].nil? ? nil : options[:width].to_f.ceil

    image = resize(image, width, height, true, options[:crop])

    if options[:crop]
      image = crop(image, width, height)
    end  
  end

  # Resize an image to a height and width.
  # If maintain_aspect_ratio (default true) is set the constraining value
  # is used when resizing the image (i.e. the largest side will match the smallest dimension)
  # otherwise the image will be resized to match the width and height.  expand_to_fit will
  # stretch the image to be at least as big as the height and width.
  # Returns an image.
  def self.resize(image, width, height, maintain_aspect_ratio=true, expand_to_fit=false)
    unless width.nil? && height.nil?
      desired_width = width
      desired_height = height
      if maintain_aspect_ratio && (!width.nil? && !height.nil?) 
        desired_ratio = width.to_f / height
        image_ratio = image.columns.to_f / image.rows
        if image_ratio > desired_ratio
          height = nil
        else
          width = nil
        end
      end
      if width.nil?
        width = height * image.columns.to_f / image.rows 
      end
      if height.nil?
        height = width * image.rows.to_f / image.columns
      end
      if expand_to_fit && (height < desired_height || width < desired_width)
        upscale = 1
        if height < desired_height
          upscale = desired_height / height
        else
          upscale = desired_width / width
        end
        width = width * upscale
        height = height * upscale
      end
      if image.columns != width && image.rows != height
        image = image.scale(width, height)
      end
    end
    return image
  end

  def self.crop(image, width, height)
    unless width.nil? && height.nil?
      image.crop!(Magick::CenterGravity, width, height)
    end
    return image
  end
end

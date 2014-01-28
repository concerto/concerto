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
    
    return image
  end


  # Compute the size of a new image.
  # Using the size of the existing image, the desired size of the output, and some control
  # options figure out what size the output image should actually be.  By default the content
  # will be resized to be no larger than the desired output size and will maintain the aspect
  # ratio.
  #
  # Internally used by {#resize} to abstract the thinking from the doing.
  #
  # @param [Integer] image_width The current image width (all sizes in pixels).
  # @param [Integer] image_height The current image height.
  # @param [Integer] desired_width The desired output width.
  # @param [Integer] desired_height The desired output height.
  # @param [Hash{Symbol => Boolean}] options Configuration options.
  #    Setting :maintain_aspect_ratio to false will ignore the aspect ratio and just
  #    return the desired size (aka dumb stretch).  Setting :expand_to_fit true will
  #    resize the size to be no smaller than the desired output size, often used before
  #    cropping.
  # @return [Hash{Symbol => Integer}] Result hash with {:width => Integer, :height => Integer}.
  def self.compute_size(image_width, image_height, desired_width, desired_height, options={})
    options[:maintain_aspect_ratio] = true if options[:maintain_aspect_ratio].nil?
    options[:expand_to_fit] ||= false

    output_width = desired_width || 0
    output_height = desired_height || 0

    if options[:maintain_aspect_ratio]
      image_ratio = image_width.to_f / image_height  # Forcing the float here is important

      # If either of the desired outputs is missing, make up the value
      # based on the fact that we're keeping the aspect ratio the same.
      output_width = desired_height.to_f * image_ratio if output_width == 0
      output_height = desired_width.to_f / image_ratio if output_height == 0

      desired_ratio = output_width.to_f / output_height
      if image_ratio > desired_ratio
        output_height = output_width.to_f / image_ratio
      else
        output_width = output_height.to_f * image_ratio
      end

      if options[:expand_to_fit] && (output_height < desired_height || output_width < desired_width)
        upscale = 1
        if output_height < desired_height
          upscale = desired_height.to_f / output_height
        else
          upscale = desired_width.to_f / output_width
        end
        output_height = output_height * upscale
        output_width = output_width * upscale
      end
    end
    return {:width => output_width.ceil, :height => output_height.ceil}
  end

  # Resize an image to a height and width.
  #
  # @param [Image] image Image to be resized.
  # @param [Integer] width Desired width of the image.
  # @param [Integer] height Desired height of the image.
  # @param [Boolean] maintain_aspect_ratio Maintain the aspect ratio when resizing.
  # @param [Boolean] expand_to_fit When false, the content will be no larger than
  #    the desired size.  When true, the content will be no smaller than the desired size.
  # @return [Image] The resized image.
  def self.resize(image, width, height, maintain_aspect_ratio=true, expand_to_fit=false)
    if !width.nil? && !height.nil? && width <= 0 && height <= 0
      image = self.new_image(0, 0)
    elsif !width.nil? || !height.nil?
      options = {
        :maintain_aspect_ratio => maintain_aspect_ratio,
        :expand_to_fit => expand_to_fit
      }
      size = self.compute_size(image.columns, image.rows, width, height, options)
      if image.columns != size[:width] && image.rows != size[:height]
        image = image.scale(size[:width], size[:height])
      end
    end
    return image
  end

  # Crop an image to a width and height.
  #
  # @param [Image] image Image to be cropped.
  # @param [Integer] width Width of the area to be cropped.
  # @param [Integer] height Height of the area to be cropped.
  # @return [Image] The cropped image, focused on the center of the image.
  def self.crop(image, width, height)
    unless width.nil? && height.nil?
      image.crop!(Magick::CenterGravity, width, height)
    end
    return image
  end

  # Create a new image
  #
  # @param [Integer] width Width of the image
  # @param [Integer] height Height of the image
  # @return [Image] The image
  def self.new_image(width, height)
    return Magick::Image.new(width, height)
  end
end

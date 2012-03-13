# Common image utilities.
module ImageUtility

  # Resize an image to a height and width.
  # If maintain_aspect_ratio (default true) is set the constraining value
  # is used when resizing the image (i.e. the largest side will match the smallest dimension)
  # otherwise the image will be resized to match the width and height.
  # Returns an image.
  def self.resize(image, width, height, maintain_aspect_ratio=true)
    unless width.nil? && height.nil?
      if maintain_aspect_ratio && (!width.nil? && !height.nil?) 
        desired_ratio = width.to_f / height
        image_ratio = image.columns.to_f / image.rows
        Rails.logger.debug(desired_ratio)
        Rails.logger.debug(image_ratio)
        Rails.logger.debug("Done")
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
      if image.columns != width && image.rows != height
        image = image.scale(width, height)
      end
    end
    return image
  end
end

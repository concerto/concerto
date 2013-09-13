class GraphicValidator < ActiveModel::Validator
  # Validator for Media associated with a Graphic.
  def validate(record)
    graphic_types = ["image/gif", "image/jpeg", "image/pjpeg", "image/png", "image/svg+xml", "image/tiff"]
    if !record.media.empty? && !graphic_types.include?(record.media[0].file_type)
      record.errors.add :media, "file is #{record.media[0].file_type}, not a graphic format we support."
    end
  end
end

class Graphic < Content

  after_initialize :set_kind

  #Validations
  validates :duration, :numericality => { :greater_than => 0 }
  validates :media, :length => { :minimum => 1, :too_short => "file is required." }
  validates_with GraphicValidator
  
  # Automatically set the kind for the content
  # if it is new.
  def set_kind
    return unless new_record?
    self.kind = Kind.where(:name => 'Graphics').first
  end

  # Responsible for display transformations on an image.
  # Resizes the image to fit a width and height specified (both required ATM).
  # Returns a new (unsaved) Media instance OR a hash with text to render
  def render(options={})
    cache_key = options
    cache_key[:content_id] = self.id
    begin
      image_hash = Rails.cache.read(cache_key)
    rescue Exception => e
      image_hash = nil
      Rails.logger.info("Cache read triggered error - #{e.message}")
    end
    if !image_hash.nil?
      Rails.logger.debug('Cache hit!')
      file = Media.new(
        :attachable => self,
        :file_data => image_hash[:data],
        :file_type => image_hash[:type],
        :file_name => image_hash[:name]
      )
      return file
    end
    Rails.logger.debug('Cache miss!')

    # If a media_id was passed in then use that media item (for graphic preview).  This
    # happens when there is no graphic record yet, but a preview is requested on the 
    # media that was uploaded.
    if options.include?(:media_id)
      preferred_media = Media.find(options[:media_id])
    else
      preferred_media = self.media.preferred.first
    end
    file = preferred_media

    options[:crop] ||= false

    if options.key?(:width) || options.key?(:height)

      if options.key?(:width) && options.key?(:height) &&
         options[:height].to_f == 0 && options[:width].to_f == 0
        return {:status => 400, :text => "Bad Request.", :content_type => Mime::TEXT}
      end

      require 'concerto_image_magick'
      image = ConcertoImageMagick.graphic_transform(preferred_media, options)
      
      file = Media.new(
        :attachable => self,
        :file_data => image.to_blob,
        :file_type => image.mime_type,
        :file_name => preferred_media.file_name
      )
    end

    cache_data = {:data => file.file_contents, :type => file.file_type, :name => file.file_name}
    begin
      Rails.cache.write(cache_key, cache_data, :expires_in => 2.hours, :race_condition_ttl => 1.minute)
    rescue Exception => e
      Rails.logger.info("Cache write triggered error - #{e.message}")
    end

    return file
  end

  # Placeholder attributes for rendering.
  attr_accessor :screen, :field

  # Store the information needed when generating the path to the image.
  def pre_render(screen, field)
    self.screen = screen
    self.field = field
  end

  # Generate the path to the iamge to be displayed.
  def render_details
    {:path => "#{Rails.application.config.relative_url_root}#{url_helpers.frontend_screen_field_content_path(self.screen, self.field, self)}"}
  end

  # Graphics also accept media attributes for the uploaded file.
  def self.form_attributes
    attributes = super()
    attributes.concat([{:media_attributes => [:file, :key, :id]}])
  end

  # returns an image tag that contains the src path to render the preview
  def self.preview(data)
    # this seems wrong to return html here in the model
    return "<img src='#{Rails.application.routes.url_helpers.display_content_path(0, :media_id => data['media_id'], :width => data['width'], :type => 'Graphic')}' />"
  end

end


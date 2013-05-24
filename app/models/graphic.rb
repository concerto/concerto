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
  # Returns a new (unsaved) Media instance.
  def render(options={})
    cache_key = options
    cache_key[:content_id] = self.id
    image_hash = Rails.cache.read(cache_key)
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

    original_media = self.media.original.first
    file = original_media

    options[:crop] ||= false

    if options.key?(:width) || options.key?(:height)
      require 'concerto_image_magick'
      image = ConcertoImageMagick.graphic_transform(original_media, options)
      
      file = Media.new(
        :attachable => self,
        :file_data => image.to_blob,
        :file_type => image.mime_type,
        :file_name => original_media.file_name
      )
    end

    cache_data = {:data => file.file_contents, :type => file.file_type, :name => file.file_name}
    Rails.cache.write(cache_key, cache_data, :expires_in => 2.hours, :race_condition_ttl => 1.minute)

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
    {:path => url_helpers.frontend_screen_field_content_path(self.screen, self.field, self)}
  end

  # Graphics also accept media attributes for the uploaded file.
  def self.form_attributes
    attributes = super()
    attributes.concat([{:media_attributes => [:file, :key]}])
  end

end


class Graphic < Content

  after_initialize :set_kind

  #Validations
  validates :duration, :numericality => { :greater_than => 0 }
  validates :media, :length => { :minimum => 1, :too_short => "At least 1 file is required." }
  
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
    original_media = self.media.original.first
    # In theory, there should be more code in here to look for a cached image and be smarter
    # about the resizing, but this is a good first pass.
    if options.key?(:width) || options.key?(:height)
      require 'image_utility'
      image = Magick::Image.from_blob(original_media.file_contents).first

      # Resize the image to a height and width if they are both being set.
      # Round these numbers up to ensure the image will at least fill
      # the requested space.
      height = options[:height].nil? ? nil : options[:height].to_f.ceil
      width = options[:width].nil? ? nil : options[:width].to_f.ceil

      image = ImageUtility.resize(image, width, height, true)

      file = Media.new(
        :attachable => self,
        :file_data => image.to_blob,
        :file_type => image.mime_type,
        :file_name => original_media.file_name
      )

      return file
    else
      return original_media
    end
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

end

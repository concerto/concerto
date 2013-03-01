class GraphicValidator < ActiveModel::Validator
  # Validator for Media associated with a Graphic.
  def validate(record)
    graphic_types = ["image/gif", "image/jpeg", "image/pjpeg", "image/png", "image/svg+xml", "image/tiff"]
    if !record.media.empty? && !graphic_types.include?(record.media[0].file_type)
      record.errors.add :media, "File is #{record.media[0].file_type}, not a graphic format we support."
    end
  end
end

class Graphic < Content

  after_initialize :set_kind

  #Validations
  validates :duration, numericality: { greater_than: 0 }
  validates :media, length: { minimum: 1, too_short: "At least 1 file is required." }
  validates_with GraphicValidator
  
  # Automatically set the kind for the content
  # if it is new.
  def set_kind
    return unless new_record?
    self.kind = Kind.where(name: 'Graphics').first
  end

  # Responsible for display transformations on an image.
  # Resizes the image to fit a width and height specified (both required ATM).
  # Returns a new (unsaved) Media instance.
  def render(options={})
    original_media = self.media.original.first
    # In theory, there should be more code in here to look for a cached image and be smarter
    # about the resizing, but this is a good first pass.

    options[:crop] ||= false

    if options.key?(:width) || options.key?(:height)
      require 'image_utility'
      image = nil
      Graphic.benchmark("Image#from_blob") do
        image = Magick::Image.from_blob(original_media.file_contents).first
      end

      # Resize the image to a height and width if they are both being set.
      # Round these numbers up to ensure the image will at least fill
      # the requested space.
      height = options[:height].nil? ? nil : options[:height].to_f.ceil
      width = options[:width].nil? ? nil : options[:width].to_f.ceil

      Graphic.benchmark("ImageUtility#resize") do
        image = ImageUtility.resize(image, width, height, true, options[:crop])
      end
      if options[:crop]
        Graphic.benchmark("ImageUtility#crop") do
          image = ImageUtility.crop(image, width, height)
        end
      end

      file = Media.new(
        attachable: self,
        file_data: image.to_blob,
        file_type: image.mime_type,
        file_name: original_media.file_name
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
    {path: url_helpers.frontend_screen_field_content_path(self.screen, self.field, self)}
  end

  # Graphics also accept media attributes for the uploaded file.
  def self.form_attributes
    attributes = super()
    attributes.concat([{media_attributes: [:file, :key]}])
  end

end


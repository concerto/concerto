class Graphic < Content

  after_initialize :set_kind

  #Validations
  validates :duration, :numericality => { :greater_than => 0 }
  validates :medias, :length => { :minimum => 1, :too_short => "At least 1 file is required." }
  
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
    # In theory, there should be more code in here to look for a cached image and be smarter
    # about the resizing, but this is a good first pass.
    if options.key?(:width) && options.key?(:height)
      require 'RMagick'
      @media = self.medias.original.first

      image = Magick::ImageList.new
      image.from_blob(@media.file_contents)
      image.resize!(options[:width].to_i, options[:height].to_i)

      file = Media.new(
        :attachable => self,
        :file_data => image.to_blob,
        :file_type => image.mime_type,
        :file_name => @media.file_name
      )

      return file
    end
  end

end

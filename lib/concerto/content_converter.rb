module Concerto

  # Class to convert various mime types for content media
  class ContentConverter
    # To add another converter, add the array of what it handles here, and then in 
    # the supported_types method also.  Then in the convert method call your converter.
    DOCSPLIT_TYPES = [
      "application/msword",
      "application/pdf",
      "application/vnd.ms-excel",
      "application/vnd.ms-powerpoint",
      "application/vnd.oasis.opendocument.graphics",
      "application/vnd.oasis.opendocument.presentation",
      "application/vnd.oasis.opendocument.spreadsheet",
      "application/vnd.oasis.opendocument.text",
      "application/vnd.openxmlformats-officedocument.presentationml.presentation",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "image/x-eps"
    ]

    # Returns an array of all supported mime-types.
    def self.supported_types
      return DOCSPLIT_TYPES
    end

    # Delegate the conversion of the media if no processed entries already exist,
    #   and if there is a converter class that supports it's mime type.
    # @param media [Media] the media to convert
    # @return media [Media] the original media, along with any processed media
    # @raise [Unconvertable] if there is no converter class that handles the media's mime type.
    def self.convert(media)
      if media.any? { |m| m.key == 'processed' }
        Rails.logger.info('media already processed')
        return media
      end

      if media.size > 0 && DOCSPLIT_TYPES.include?(media[0].file_type)
        return DocSplitConverter.convert media 
      end

      raise Unconvertable.new("Unable to convert the specified type #{media[0].file_type}") 
    end

    # When a document cannot be converted, this exception will be raised.
    class Unconvertable < StandardError
      def initialize(message = nil)
        @message = message
      end

      def to_s
        @message || "Unable to convert"
      end
    end

    # Class for converting various document types using the docsplit gem.
    class DocSplitConverter
      require 'docsplit'

      # Converts the first page of the original media to a png and loads it back into 
      #   the media as a processed entry.
      # @param media [Media] the media to convert
      # @return media [Media] the original media, along with any processed media
      # @raise [Unconvertable] if there is no converter class that handles the media's mime type.
      def self.convert(media)
        # write the original media to a file so we can process it and pull it back into media
        original_media = media[0]
        original_filepath = File.join("/tmp", original_media.file_name)
        File.open(original_filepath, 'wb') do |f|
          f.write original_media.file_contents
        end

        # process it with docsplit via the api
        begin
          Docsplit.extract_images("#{original_filepath}", :pages => 1, :format => 'png', :output => "/tmp")

          # if all went well, get the new filename... which has the _pageno appended to it
          new_filename = "#{File.basename(original_filepath,".*")}_1.png"
          new_filepath = File.join( File.dirname(original_filepath), new_filename)

          # ... and load into into the new media...
          image = Magick::Image::read(new_filepath).first
          image.alpha(Magick::DeactivateAlphaChannel)
          new_media = Media.new(
            :attachable => original_media.attachable,
            :key => 'processed',
            :file_data => image.to_blob,
            :file_type => image.mime_type,
            :file_name => new_filename,
            :file_size => image.filesize
          )
          media << new_media
          File.delete(original_filepath) if File.exist?(original_filepath)
          File.delete(new_filepath) if File.exist?(new_filepath)
          return media
        rescue Docsplit::ExtractionFailed => e
          Rails.logger.error(e.message.chomp)
          raise Unconvertable.new("Unable to convert #{original_media.file_name}")
        end
      end
    end
  end
end

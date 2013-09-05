module Concerto

  class ContentConverter
    # To add another converter, add the array of what it handles here, and then in the handles? method
    # check that array also.  In the convert method call your converter.
    NULL_TYPES = [
      "image/gif",
      "image/jpeg",
      "image/pjpeg",
      "image/png",
      "image/svg+xml",
      "image/tiff"
    ]
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

    def self.handles? file_type
      (NULL_TYPES + DOCSPLIT_TYPES).include? file_type
    end

    def self.convert media
      # convert the media if no processed entries already exist
      if media.any? { |m| m.key == 'processed' }
        Rails.logger.info('media already processed')
        return media
      end

      return NullConverter.convert media if NULL_TYPES.include? media[0].file_type
      return DocSplitConverter.convert media if DOCSPLIT_TYPES.include?(media[0].file_type)

      raise Unconvertable.new("Unable to convert the specified type #{media[0].file_type}") 
    end

    class Unconvertable < StandardError
      def initialize(message = nil)
        @message = message
      end

      def to_s
        @message || "Unable to convert"
      end
    end

    class NullConverter
      # do nothing, we handle these formats natively
      def self.convert media
        return media
      end
    end

    class DocSplitConverter
      def self.convert media
        # write the original media to a file so we can process it and pull it back into media
        original_media = media[0]
        original_filepath = File.join("/tmp", original_media.file_name)
        File.open(original_filepath, 'wb') do |f|
          f.write original_media.file_data
        end

        # process it with docsplit
        cmd = "docsplit images -p 1 -f png -o /tmp '#{original_filepath}' 2>&1"
        result = `#{cmd}`
        if $?.exitstatus == 0
          # if all went well, get the new filename... which has the _pageno appended to it
          new_filename = "#{File.basename(original_filepath,".*")}_1.png"
          new_filepath = File.join( File.dirname(original_filepath), new_filename)

          # ... and load into into the new media...
          image = Magick::Image::read(new_filepath).first
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
        else
          # command failed
          Rails.logger.error(cmd)
          Rails.logger.error(result)
          raise Unconvertable.new("Unable to convert #{original_media.file_name}, see log for more details")
        end
      end
    end
  end
end

class Template < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  has_many :screens, :dependent => :restrict_with_exception
  has_many :media, :as => :attachable, :dependent => :destroy
  has_many :positions, :dependent => :destroy
  
  accepts_nested_attributes_for :media
  accepts_nested_attributes_for :positions, :allow_destroy => true
  
  belongs_to :owner, :polymorphic => true

  # Validations
  validates :name, :presence => true, :uniqueness => true

  #Placeholder attributes
  attr_accessor :path, :css_path
  
  def is_deletable?
    self.screens.size == 0
  end
    
  # Given a string from an XML descriptor, build the template
  # to try and match the description.  Each position will be
  # constructed from the descriptor.  If a position can't be
  # validated, usually because there was no matching field,
  # that position will be rejected but the other sucessful
  # positions will be saved.
  #
  # This means that many templates may only import a few of
  # their fields(v1 term) / positions(v2 term).  We'll either
  # need to strengthn up the matching approach or clean the
  # templates we make publicly available.
  def import_xml(xml)
    data = Hash::from_xml(xml)
    
    self.name = data['template']['name']
    self.author = data['template']['author']
    self.is_hidden = data['template']['hidden']

    if data['template'].has_key?('field')
      data['template']['field'] = [data['template']['field']] unless data['template']['field'].kind_of?(Array)
      data['template']['field'].each do |field|
        position = self.positions.build
        position.import_hash(field)
        if !position.valid?
          # This position might not actually be deleted,
          # instead it will be marked for deletion (aka not creating it)
          position.destroy
        end
      end
    end
    return self.valid?
  end


  # Update the original_width and original_height
  # fields using the orignal image.
  # !! this does not appear to be called from anywhere
  def update_original_sizes
    original_media = self.media.original.first
    unless original_media.nil?
      require 'concerto_image_magick'
      image = ConcertoImageMagick.load_image(self.media.original.first.file_contents)
      self.original_width = image.columns
      self.original_height = image.rows
    end
    return true
  end

  # Find the last time this template was modified by looking at the
  # template, fields, and original media.  Return the largest update_at value.
  def last_modified
    timestamps = [updated_at]
    latest_position = positions.order('updated_at DESC').first
    timestamps.append(latest_position.updated_at) unless latest_position.nil?
    latest_media = media.original.order('updated_at DESC').first
    timestamps.append(latest_media.updated_at) unless latest_media.nil?
    return timestamps.max
  end

  # Generate a preview image of a template.
  # Hide the fields all together, or just hide the field text.
  # Or just show certain fields
  def preview_image(hide_fields=false, hide_text=false, only_fields=[])
    require 'concerto_image_magick'

    if self.media.blank?
      image = ConcertoImageMagick.new_image(1024, 768);
    else
      image = ConcertoImageMagick.load_image(self.media.preferred.first.file_contents)
    end

    height = image.rows
    width = image.columns

    if !hide_fields && !self.positions.empty?
      dw = ConcertoImageMagick.new_drawing_object()
      
      self.positions.each do |position|
        if !only_fields.empty? && !only_fields.include?(position.field_id)
          next
        end
        
        dw = ConcertoImageMagick.draw_block(dw, :fill_color => "black", :stroke_opacity => 0, :fill_opacity => 0.6, :width => width, :height => height, :left => position.left, :right => position.right, :top => position.top, :bottom => position.bottom)

        if !hide_text
          dw = ConcertoImageMagick.draw_text(dw,:stroke_color => "white", :fill_color => "white", :opacity => 1, :width => width, :height => height, :left => position.left, :right => position.right, :top => position.top, :bottom => position.bottom, :field_name => position.field.name)
        end
      end
      ConcertoImageMagick.draw_image(dw,image)
    end
    return image
  end

  def import_archive(archive)
    if archive.blank?
      self.errors.add(:base, I18n.t('templates.new.template_import_requires_archive'))
      return false
    end

    unless archive.content_type.include? 'zip'
      self.errors.add(:base, I18n.t('templates.new.template_import_requires_zip'))
      return false
    end

    file = archive.tempfile unless archive.is_a? Rack::Test::UploadedFile
    file ||= archive

    require 'zip/zip'
    zip_file = Zip::ZipFile.open(file)
    xml_data = image_file = nil
    css_file = nil
    zip_file.each do |entry|
      # Skip anything in the hidden __macosx directory.
      next if entry.name.downcase.include?('__macosx/')

      extension = entry.name.split('.')[-1].downcase
      if extension == 'xml'
        xml_data = entry.get_input_stream.read
      elsif extension == 'css'
        css_file = entry
      elsif ['jpg', 'png'].include?(extension) && !entry.name.include?('preview')
        image_file = entry
      end
    end

    if xml_data.blank?
      self.errors.add(:base, I18n.t('templates.new.template_import_requires_xml'))
      return false
    end

    if image_file.blank?
      self.errors.add(:base, I18n.t('templates.new.template_import_requires_image'))
      return false
    end

    if import_xml(xml_data)
      self.media.build({:key=>"original", :file_name => image_file.name,
                             :file_type => MIME::Types.type_for(image_file.name).first.content_type})
      self.media.first.file_size = image_file.size
      self.media.first.file_data = image_file.get_input_stream.read

      if !css_file.nil?
        m = self.media.build({:key=>"css", :file_name => css_file.name,
                               :file_type => MIME::Types.type_for(css_file.name).first.content_type})
        m.file_size = css_file.size
        m.file_data = css_file.get_input_stream.read
      end
      return true
    else
      self.errors.add(:base, I18n.t('templates.new.invalid_xml'))
      return false
    end
  end
end

class Template < ActiveRecord::Base
  has_many :screens
  has_many :media, :as => :attachable, :dependent => :destroy
  has_many :positions, :dependent => :destroy
  
  accepts_nested_attributes_for :media

  # Validations
  validates :name, :presence => true

  #Placeholder attributes
  attr_accessor :path
  
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
  def update_original_sizes
    original_media = self.media.original.first
    unless original_media.nil?
      image = Magick::Image.from_blob(original_media.file_contents).first
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
    timestamps.append(latest_media.updated_at)
    return timestamps.max
  end

  # Generate a preview image of a template.
  # Hide the fields all together, or just hide the field text.
  # Or just show certain fields
  def preview_image(hide_fields=false, hide_text=false, only_fields=[])
    template_media = self.media.original.first
    image = Magick::Image.from_blob(template_media.file_contents).first

    height = image.rows
    width = image.columns

    if !hide_fields && !self.positions.empty?
      dw = Magick::Draw.new
      self.positions.each do |position|
        Rails.logger.debug(only_fields)
        Rails.logger.debug(position.field_id)
        if !only_fields.empty? && !only_fields.include?(position.field_id)
          next
        end
        #Draw the rectangle
        dw.fill("black")
        dw.stroke_opacity(0)
        dw.fill_opacity(0.6)
        dw.rectangle(width*position.left, height*position.top,
                     width*position.right, height*position.bottom)

        if !hide_text
          #Layer the field name
          dw.stroke("white")
          dw.fill("white")
          dw.text_anchor(Magick::MiddleAnchor)
          dw.opacity(1)
          font_size = [width, height].min / 8
          dw.pointsize = font_size
          dw.text((width*(position.left + position.right)/2),
                  (height*(position.top + position.bottom)/2+0.4*font_size),
                  position.field.name)
        end
      end
      dw.draw(image)
    end
    return image
  end
end

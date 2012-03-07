class Template < ActiveRecord::Base
  has_many :screens
  has_many :media, :as => :attachable, :dependent => :destroy
  has_many :positions, :dependent => :destroy
  
  accepts_nested_attributes_for :media

  #Validations
  validates :name, :presence => true
  
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
end

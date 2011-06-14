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

    data['template']['field'] = [data['template']['field']] unless data['template']['field'].kind_of?(Array)        
    data['template']['field'].each do |field|
      position = self.positions.build
      field.each_pair do |key, value|
        position.send("#{key}=".to_sym, value) if position.respond_to?("#{key}=".to_sym)
      end
      if field.has_key?('name')
        position.field = Field.where(:name => field['name']).first
      end
      if !position.valid?
        # This position might not actually be deleted,
        # instead it will be marked for deletion (aka not creating it)
        position.destroy
      end
    end
    return self.valid?
  end
end

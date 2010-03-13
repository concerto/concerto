class Position < ActiveRecord::Base
  belongs_to :field
  belongs_to :template
  
  #Validations
  validates_uniqueness_of :field_id, :scope => :template_id
  
  #Some Concerto-1 style attributes
  def width
    right-left
  end
  
  def height
    bottom-top
  end
end

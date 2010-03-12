class Position < ActiveRecord::Base
  belongs_to :field
  belongs_to :template
  
  #Validations
  validates_uniqueness_of :field_id, :scope => :template_id
end

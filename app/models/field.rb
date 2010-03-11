class Field < ActiveRecord::Base
  belongs_to :type
  
  #Validations
  validates :name, :presence => true
end

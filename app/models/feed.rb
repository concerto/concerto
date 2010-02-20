class Feed < ActiveRecord::Base
  belongs_to :group

  #Validations
  validates :name, :presence => true
end

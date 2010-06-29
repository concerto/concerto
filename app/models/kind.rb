class Kind < ActiveRecord::Base
  has_many :contents
  has_many :fields

  #Validations
  validates :name, :presence => true, :uniqueness => true
end

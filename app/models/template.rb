class Template < ActiveRecord::Base
  has_many :screens

  #Validations
  validates :name, :presence => true
end

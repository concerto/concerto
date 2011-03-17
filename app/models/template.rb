class Template < ActiveRecord::Base
  has_many :screens
  has_many :media, :as => :attachable
  has_many :positions
  
  accepts_nested_attributes_for :media

  #Validations
  validates :name, :presence => true
end

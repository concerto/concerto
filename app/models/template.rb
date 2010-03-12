class Template < ActiveRecord::Base
  has_many :screens
  has_many :medias, :as => :attachable
  has_many :positions
  
  accepts_nested_attributes_for :medias

  #Validations
  validates :name, :presence => true
end

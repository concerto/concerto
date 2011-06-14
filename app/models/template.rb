class Template < ActiveRecord::Base
  has_many :screens
  has_many :media, :as => :attachable, :dependent => :destroy
  has_many :positions, :dependent => :destroy
  
  accepts_nested_attributes_for :media

  #Validations
  validates :name, :presence => true
end

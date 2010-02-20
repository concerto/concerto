class Feed < ActiveRecord::Base
  belongs_to :group
  has_many :submissions
  has_many :contents, :through => :submissions

  #Validations
  validates :name, :presence => true
end

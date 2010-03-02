class Group < ActiveRecord::Base
  has_many :feeds

  #Validations
  validates :name, :presence => true, :uniqueness => true
end

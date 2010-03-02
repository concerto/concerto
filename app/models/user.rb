class User < ActiveRecord::Base
  has_many :contents
  has_many :submisions
  
  #Validations
  validates :username, :presence => true, :uniqueness => true
  validates :email, :presence => true, :uniqueness => true
end

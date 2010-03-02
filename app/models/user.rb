class User < ActiveRecord::Base
  has_many :contents
  has_many :submissions, :foreign_key => "moderator_id"
  
  #Validations
  validates :username, :presence => true, :uniqueness => true
  validates :email, :presence => true, :uniqueness => true
  
  def name
    first_name + " " + last_name
  end
end

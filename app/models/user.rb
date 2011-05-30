class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  has_many :contents
  has_many :submissions, :foreign_key => "moderator_id"
  has_many :memberships, :dependent => :destroy
  has_many :groups, :through => :memberships
  has_many :screens, :as => :owner

  
  #Validations
  validates :username, :presence => true, :uniqueness => true
  validates :email, :presence => true, :uniqueness => true
  
  # Use the username instead of the id in URL's and stuff
  def to_param
    username
  end

  # A simple name, combining the first and last name
  # We should probably expand this so it doesn't look stupid
  # if people only have a first name or only have a last name
  def name
    first_name + " " + last_name
  end

  # Quickly test if a user belongs to a group
  def in_group?(group)
    groups.include?(group)
  end
  
end

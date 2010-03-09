class Group < ActiveRecord::Base
  has_many :feeds
  has_many :memberships, :dependent => :destroy
  has_many :users, :through => :memberships
  has_many :screens, :as => :owner

  #Scoped relations for leaders
  has_many :leaders, :through => :memberships, :source => :user, :conditions => {"memberships.is_leader" => true}  

  #Validations
  validates :name, :presence => true, :uniqueness => true

  #Test if a member is part of this group
  def has_member?(user)
    users.include?(user)
  end

end

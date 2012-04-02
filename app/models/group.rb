class Group < ActiveRecord::Base
  has_many :feeds
  has_many :memberships, :dependent => :destroy
  has_many :users, :through => :memberships, :conditions => ["memberships.level > ?", Membership::LEVELS[:pending]]
  has_many :screens, :as => :owner

  # Scoped relation for members and pending members
  has_many :all_users, :through => :memberships, :source => :user, :conditions => ["memberships.level != ?", Membership::LEVELS[:denied]]

  # Scoped relations for leaders
  has_many :leaders, :through => :memberships, :source => :user, :conditions => {"memberships.level" => Membership::LEVELS[:leader]}  

  # Validations
  validates :name, :presence => true, :uniqueness => true

  # Test if a user is part of this group
  def has_member?(user)
    users.include?(user)
  end

  # Test if a user has requested membership in this group
  def made_request?(user)
    all_users.include?(user)
  end

end

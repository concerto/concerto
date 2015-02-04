class Group < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  after_create :create_leader

  has_many :feeds, :dependent => :restrict_with_error
  has_many :memberships, :dependent => :destroy
  accepts_nested_attributes_for :memberships

  has_many :users, -> { where ["memberships.level > ?", Membership::LEVELS[:pending]] }, :through => :memberships
  has_many :screens, :as => :owner, :dependent => :restrict_with_error

  has_many :templates, :as => :owner

  # Scoped relation for members and pending members
  has_many :all_users, -> { where ["memberships.level != ?", Membership::LEVELS[:denied]] }, :through => :memberships, :source => :user

  # Scoped relation for leaders
  has_many :leaders, -> { where "memberships.level" => Membership::LEVELS[:leader] }, :through => :memberships, :source => :user

  # Validations
  validates :name, :presence => true, :uniqueness => true

  before_save :update_membership_perms

  #Newsfeed
  include PublicActivity::Common if defined? PublicActivity::Common

  #have getters and setters for a new_leader virtual attribute
  attr_accessor :new_leader

  # Manually cascade the callbacks for membership permissions.
  def update_membership_perms
    self.memberships.each do |m|
      m.run_callbacks(:save)
    end
  end

  def create_leader
    self.new_leader = Membership.create(:user_id => new_leader, :group_id => self.id, :level => Membership::LEVELS[:leader]) if new_leader.present?
  end

  # Deliver a list of only users not currently in the group
  # Used for adding new users to a group and avoiding duplication
  def users_not_in_group
    users = User.all.to_a
    self.memberships.each do |m|
      users.delete_if { |key, value| key.id == m.user_id }
    end
    return users
  end

  def is_deletable?
    self.screens.size == 0 && self.feeds.size == 0
  end

  # Test if a user is part of this group
  def has_member?(user)
    users.include?(user)
  end

  # Test if a user has requested membership in this group
  def made_request?(user)
    all_users.include?(user)
  end

  # Test if a user has a certain permission at a level within a group.
  # Sample usage: user_has_permissions?(user, :regular, :screen, [:subscribe, :all])
  # will test if the `user` has either :all or :subscribe permissions as a supporter in
  # the screen permission type of the current group.
  def user_has_permissions?(user, level, type, permissions)
    return false if user.nil?

    m = memberships.where(:user_id => user, :level => Membership::LEVELS[level]).first
    return false if m.nil?
    return false unless m.perms.include?(type)

    permissions = [permissions] if permissions.is_a? Symbol
    permissions.each do |p|
      return true if m.perms[type] == p
    end
    return false
  end
end

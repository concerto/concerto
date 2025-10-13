class Group < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  # Models that groups own or manage.
  has_many :screens, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  # Prevent deletion of system groups
  before_destroy :cannot_destroy_system_group

  # Finds all users in this group who are admins.
  def admins
    users.merge(Membership.admin)
  end

  # Finds all users in this group who are regular members.
  def members
    users.merge(Membership.member)
  end

  # Check if a user is a member of the group.
  def member?(user)
    return false unless user
    users.exists?(user.id)
  end

  # Check if a user is an admin of the group.
  def admin?(user)
    return false unless user
    admins.exists?(user.id)
  end

  # Class method to easily find the special group
  def self.all_users_group
    find_by(name: "All Registered Users")
  end

  # Check if this is a system group
  def system_group?
    name == "All Registered Users"
  end

  private

  def cannot_destroy_system_group
    if system_group?
      errors.add(:base, 'Cannot delete the "All Registered Users" group')
      throw(:abort)
    end
  end
end

class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :group

  # Ensures a user can only be in a group once
  validates :user_id, uniqueness: { scope: :group_id }

  # Prevent removal from system groups
  before_destroy :cannot_remove_from_system_group
  before_destroy :cannot_remove_last_system_admin

  # Define the enum for roles
  # :member will be stored as 0 in the DB, :admin as 1
  enum :role, { member: 0, admin: 1 }

  private

  def cannot_remove_from_system_group
    # Prevent manual removal from the auto-managed "All Registered Users" group,
    # but allow deletion when the record is being destroyed due to a dependent
    # destroy (e.g., user/group destroy). System Administrators is managed manually.
    return unless group&.name == Group::REGISTERED_USERS_GROUP_NAME
    return if destroyed_by_association.present?

    errors.add(:base, 'Cannot remove users from the "All Registered Users" group')
    throw(:abort)
  end

  def cannot_remove_last_system_admin
    return unless group&.system_admin_group?
    return if Membership.where(group_id: group_id).where.not(id: id).exists?

    errors.add(:base, "Cannot remove the last user from the System Administrators group")
    throw(:abort)
  end
end

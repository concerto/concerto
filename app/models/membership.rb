class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :group

  # Ensures a user can only be in a group once
  validates :user_id, uniqueness: { scope: :group_id }

  # Prevent removal from system groups
  before_destroy :cannot_remove_from_system_group

  # Define the enum for roles
  # :member will be stored as 0 in the DB, :admin as 1
  enum :role, { member: 0, admin: 1 }

  private

  def cannot_remove_from_system_group
    # Prevent manual removal from the system group, but allow deletion when this
    # record is being destroyed due to a dependent destroy (e.g., user/group destroy).
    return unless group&.system_group?
    return if destroyed_by_association.present?

    errors.add(:base, 'Cannot remove users from the "All Registered Users" group')
    throw(:abort)
  end
end

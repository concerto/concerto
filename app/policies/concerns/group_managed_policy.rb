# frozen_string_literal: true

# GroupManagedPolicy provides shared authorization logic for entities
# that are owned and managed by Groups (e.g., Screens, Feeds).
#
# This concern extracts common patterns where:
# - Group admins can create and destroy entities
# - Group members can edit entities
# - Moving entities between groups requires admin permissions on both groups
# - System admins can override all restrictions
#
# Usage:
#   class ScreenPolicy < ApplicationPolicy
#     include GroupManagedPolicy
#
#     def entity_specific_attributes
#       [:name, :template_id]
#     end
#   end
module GroupManagedPolicy
  extend ActiveSupport::Concern

  included do
    class Scope < ApplicationPolicy::Scope
      # Group-managed entities are visible to all users, even anonymous users.
      def resolve
        scope.all
      end
    end
  end

  # Template method for subclasses to define their specific attributes.
  # This is used by permitted_attributes to build the complete attribute list.
  #
  # Example:
  #   def entity_specific_attributes
  #     [:name, :template_id]
  #   end
  def entity_specific_attributes
    raise NotImplementedError, "#{self.class} must implement #entity_specific_attributes"
  end

  # Check if user can create a new entity (without a specific group yet).
  # Users can create new entities if they are admin of at least one group.
  def can_create_new?
    return false unless user
    user.admin_groups.any?
  end

  # Check if user can create this specific entity.
  # If the entity doesn't have a group yet, falls back to can_create_new?
  # Otherwise, checks if the user is an admin of the entity's group.
  def can_create?
    return false unless user
    return can_create_new? unless record.group
    record.group.admin?(user)
  end

  # Check if user can edit this entity.
  # Users can edit entities if they are a member of the entity's group.
  def can_edit?
    return false unless user
    record.group&.member?(user)
  end

  # Check if user can update this entity.
  # Users can update if they can edit, but group changes require special handling:
  # - User must be admin of the old group (if it existed)
  # - User must be admin of the new group
  def can_update?
    return false unless can_edit?

    # If group_id is being changed, ensure user is admin of both
    # the current group and the new group.
    if record.group_id_changed?
      # Check permissions on the old group, if it existed.
      if record.group_id_was.present?
        old_group = Group.find_by(id: record.group_id_was)
        return false unless old_group&.admin?(user)
      end

      # Check permissions on the new group.
      # The `record` is already associated with the new group object.
      return false unless record.group&.admin?(user)
    end

    true
  end

  # Check if user can destroy this entity.
  # Users can destroy entities if they are an admin of the entity's group.
  def can_destroy?
    return false unless user
    record.group&.admin?(user)
  end

  # Returns the list of permitted attributes for this entity.
  # Includes entity-specific attributes plus :group_id if user can edit the group.
  def permitted_attributes
    if can_edit_group?
      entity_specific_attributes + [ :group_id ]
    else
      entity_specific_attributes
    end
  end

  # Helper method to determine if the user can edit the group which owns the entity.
  #
  # This is used both in the policy and in the view to disable UI elements.
  # System admins can always edit groups.
  # For new records, any logged-in user can see/edit the group field in the UI.
  #   (The actual security check happens in can_create?, which verifies the user
  #   is admin of the selected group before allowing creation.)
  # For existing records, only admins of the current group can change it.
  def can_edit_group?
    return true if user&.system_admin?
    return false unless user
    record.new_record? || record.group&.admin?(user)
  end
end

class FeedPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    # All users (including anonymous) can see all feeds
    def resolve
      scope.all
    end
  end

  def index?
    # Everyone can view the list
    true
  end

  def show?
    # Everyone can view individual feeds
    true
  end

  def new?
    super || can_create_new_feed?
  end

  def create?
    # Once Feed has group_id, this will check group admin permissions
    super || can_create_feed?
  end

  def edit?
    # Once Feed has group_id, this will check group member permissions
    super || can_edit_feed?
  end

  def update?
    # Once Feed has group_id, this will check group member permissions
    super || can_update_feed?
  end

  def destroy?
    # Once Feed has group_id, this will check group admin permissions
    super || can_destroy_feed?
  end

  def refresh?
    # Refresh requires update permissions
    update?
  end

  def cleanup?
    # Cleanup requires update permissions
    update?
  end

  private

  # Feeds can be created by any admin of any group
  def can_create_new_feed?
    return false unless user
    user.admin_groups.any?
  end

  # Feeds can be created by any admin of the associated group.
  # If no group is assigned yet, fallback to checking if user is admin of any group.
  def can_create_feed?
    return false unless user
    return can_create_new_feed? unless record.group
    record.group.admin?(user)
  end

  # Feeds can be edited by any member of the associated group.
  def can_edit_feed?
    return false unless user
    record.group.member?(user)
  end

  # Feeds can be updated by members of the group, but group changes
  # require admin permissions on both the old and new groups.
  def can_update_feed?
    return false unless can_edit_feed?

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

  # Feeds can be deleted by any admin of the associated group.
  def can_destroy_feed?
    return false unless user
    record.group.admin?(user)
  end

  public

  def permitted_attributes
    # System admins can edit all attributes
    # Once Feed has group_id, non-admins will have restricted permissions
    if can_edit_group?
      [ :name, :description, :type, :config, :group_id ]
    else
      [ :name, :description, :type, :config ]
    end
  end

  # Helper method to determine if the user can edit the group which owns a feed.
  #
  # This is used both in the policy and in the view to disable UI elements.
  def can_edit_group?
    return true if user&.system_admin?
    return false unless user
    record.new_record? || record.group.admin?(user)
  end
end

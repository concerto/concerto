class ScreenPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  class Scope < ApplicationPolicy::Scope
    # Screens are visible to all users, even non-logged-in users.
    def resolve
      scope.all
    end
  end

  def index?
    true
  end

  def show?
    true
  end

  def new?
    # Screens can be created by any admin of any group.
    return false unless user
    user.admin_groups.any?
  end

  def create?
    # Screens can be created by any admin of the associated group.
    return false unless user
    record.group.admin?(user)
  end

  def edit?
    # Screens can be edited by any member of the associated group.
    return false unless user
    record.group.member?(user)
  end

  def update?
    return false unless edit?

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

  def destroy?
    # Screens can be deleted by any admin of the associated group.
    return false unless user
    record.group.admin?(user)
  end

  def permitted_attributes
    if can_edit_group?
      [ :name, :template_id, :group_id ]
    else
      [ :name, :template_id ]
    end
  end

  # Helper method to determine if the user can edit the group which owns a screen.
  #
  # This is used both in the policy and in the view to disable UI elements.
  def can_edit_group?
    return false unless user
    record.new_record? || record.group.admin?(user)
  end
end

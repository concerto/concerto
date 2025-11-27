class MembershipPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    # All signed-in users can see memberships
    def resolve
      return scope.none unless user
      scope.all
    end
  end

  def index?
    # All signed-in users can see memberships
    user.present?
  end

  def show?
    # All signed-in users can see individual memberships
    user.present?
  end

  def new?
    super || can_create_membership?
  end

  def create?
    super || can_create_membership?
  end

  def edit?
    super || can_edit_membership?
  end

  def update?
    super || can_update_membership?
  end

  def destroy?
    super || can_destroy_membership?
  end

  private

  # Only admins of the group may create memberships
  def can_create_membership?
    return false unless user
    return false unless record.group.present?
    record.group.admin?(user)
  end

  # Only admins of the group may edit memberships
  def can_edit_membership?
    can_create_membership?
  end

  # Only admins of the group may update memberships
  def can_update_membership?
    can_edit_membership?
  end

  # A user may remove themselves, or they may be removed by an admin of the group
  def can_destroy_membership?
    return false unless user
    # User can remove themselves
    return true if record.user_id == user.id
    # Or admins of the group can remove anyone
    return false unless record.group.present?
    record.group.admin?(user)
  end

  public

  def permitted_attributes
    if can_edit_role?
      [ :user_id, :group_id, :role ]
    else
      [ :user_id, :group_id ]
    end
  end

  # Helper method to determine if the user can edit the role field
  # Only admins of the group can set/update the role field
  def can_edit_role?
    user.present? && (user.system_admin? || (record.group.present? && record.group.admin?(user)))
  end
end

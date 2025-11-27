class GroupPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    # All users (including anonymous) can see all groups
    def resolve
      scope.all
    end
  end

  def index?
    # Everyone can see the list
    true
  end

  def show?
    # Everyone can view individual groups
    true
  end

  def new?
    # Only system administrators can create groups
    super
  end

  def create?
    # Only system administrators can create groups
    super
  end

  def edit?
    super || can_edit_group?
  end

  def update?
    super || can_edit_group?
  end

  def destroy?
    # Only system administrators can destroy groups
    super
  end

  private

  # Only admins of the group can update it
  def can_edit_group?
    return false unless user
    record.admin?(user)
  end
end

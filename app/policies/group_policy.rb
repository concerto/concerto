class GroupPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    # Only signed-in users can see groups
    def resolve
      return scope.none unless user
      scope.all
    end
  end

  def index?
    # Only signed-in users can see the list
    user.present?
  end

  def show?
    # Only signed-in users can view individual groups
    user.present?
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

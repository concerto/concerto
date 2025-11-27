class PositionPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    # All users (including anonymous) can see all positions
    def resolve
      scope.all
    end
  end

  def index?
    # Everyone can view the list
    true
  end

  def show?
    # Everyone can view individual positions
    true
  end

  def new?
    super || can_create_position?
  end

  def create?
    super || can_create_position?
  end

  def edit?
    # Only system administrators can update positions (for now)
    super
  end

  def update?
    # Only system administrators can update positions (for now)
    super
  end

  def destroy?
    # Only system administrators can destroy positions (for now)
    super
  end

  private

  # Any admin of a group owning a screen can create a position
  def can_create_position?
    return false unless user
    user.admin_groups.joins(:screens).any?
  end
end

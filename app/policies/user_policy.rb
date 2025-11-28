class UserPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    # All signed-in users can see all users
    def resolve
      return scope.none unless user
      scope.all
    end
  end

  def index?
    # Everyone who's signed in can view the list of users
    user.present?
  end

  def show?
    # Only signed-in users can view user profiles
    user.present?
  end

  def new?
    # Defer to Devise for user creation
    true
  end

  def create?
    # Defer to Devise for user creation
    true
  end

  def edit?
    super || can_edit_user?
  end

  def update?
    super || can_edit_user?
  end

  def destroy?
    super || can_edit_user?
  end

  private

  # A user may only update/destroy themselves (system admins can manage anyone via super)
  def can_edit_user?
    return false unless user
    user.id == record.id
  end
end

class SubscriptionPolicy < ApplicationPolicy
  # Subscriptions are visible to all users, even non-logged-in users.
  # Subscriptions can be created, edited, and deleted by any member of the group associated with the screen.
  class Scope < ApplicationPolicy::Scope
    # Subscriptions are visible to all users, even non-logged-in users.
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
    member_of_screen_group?
  end

  def create?
    member_of_screen_group?
  end

  def update?
    member_of_screen_group?
  end

  def destroy?
    member_of_screen_group?
  end

  private

  def member_of_screen_group?
    return false unless user
    record.screen.group.member?(user)
  end
end

class FieldPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    # All users (including anonymous) can see all fields
    def resolve
      scope.all
    end
  end

  def index?
    # Everyone can view the list
    true
  end

  def show?
    # Everyone can view individual fields
    true
  end

  # All other actions (create, update, destroy) default to system admin only via ApplicationPolicy
end

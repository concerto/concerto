class SettingPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    # Only system admins can see settings
    def resolve
      return scope.none unless user&.system_admin?
      scope.all
    end
  end

  # All actions default to system admin only via ApplicationPolicy
  # No need to override any methods
end

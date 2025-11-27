class TemplatePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    # All users (including anonymous) can see all templates
    def resolve
      scope.all
    end
  end

  def index?
    # Everyone can view the list
    true
  end

  def show?
    # Everyone can view individual templates
    true
  end

  def new?
    super || can_create_template?
  end

  def create?
    super || can_create_template?
  end

  def edit?
    # Only system administrators can update templates (for now)
    super
  end

  def update?
    # Only system administrators can update templates (for now)
    super
  end

  def destroy?
    # Only system administrators can destroy templates (for now)
    super
  end

  private

  # Any admin of a group owning a screen can create a template
  def can_create_template?
    return false unless user
    user.admin_groups.joins(:screens).any?
  end
end

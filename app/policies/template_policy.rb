class TemplatePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    # Only signed-in users can see templates
    def resolve
      return scope.none unless user
      scope.all
    end
  end

  def index?
    # Only signed-in users can view the list
    user.present?
  end

  def show?
    # Only signed-in users can view individual templates
    user.present?
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

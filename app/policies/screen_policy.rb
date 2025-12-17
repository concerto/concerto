class ScreenPolicy < ApplicationPolicy
  include GroupManagedPolicy

  def index?
    true
  end

  def show?
    true
  end

  def new?
    super || can_create_new?
  end

  def create?
    super || can_create?
  end

  def edit?
    super || can_edit?
  end

  def update?
    super || can_update?
  end

  def destroy?
    super || can_destroy?
  end

  private

  def entity_specific_attributes
    [ :name, :template_id ]
  end
end

# frozen_string_literal: true

# FieldConfigPolicy delegates authorization to the associated Screen.
# Users can manage field configs if they can manage the screen.
class FieldConfigPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      # Users can see field configs for all screens
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
    super || screen_policy.edit?
  end

  def create?
    super || screen_policy.update?
  end

  def edit?
    super || screen_policy.edit?
  end

  def update?
    super || screen_policy.update?
  end

  def destroy?
    super || screen_policy.update?
  end

  def permitted_attributes
    [ :screen_id, :field_id, :pinned_content_id ]
  end

  private

  def screen_policy
    @screen_policy ||= ScreenPolicy.new(user, record.screen)
  end
end

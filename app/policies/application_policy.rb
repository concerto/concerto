# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    system_admin_only
  end

  def show?
    system_admin_only
  end

  def create?
    system_admin_only
  end

  def new?
    # We can't reference create? here because it is likely
    # overridden in child policies, so we need to duplicate the logic.
    system_admin_only
  end

  def update?
    system_admin_only
  end

  def edit?
    # We cannot reference update? here for the same reason as create?.
    system_admin_only
  end

  def destroy?
    system_admin_only
  end

  private

  def system_admin_only
    user&.system_admin?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end

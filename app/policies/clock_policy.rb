class ClockPolicy < ContentPolicy
  # Only screen managers (or system admins) can create Clock content
  # Clock content is specialized for screens, unlike other content types
  def new?
    user && (user.system_admin? || user.screen_manager?)
  end

  def create?
    user && (user.system_admin? || user.screen_manager?)
  end

  # All other permissions (edit?, update?, destroy?, show?, etc.)
  # are inherited from ContentPolicy
end

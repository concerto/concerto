class SubmissionPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    # All users (including anonymous) can see all submissions
    def resolve
      scope.all
    end
  end

  # Scope for moderation queue - only submissions in feeds the user can moderate
  class ModerationScope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      # System admins can moderate all submissions
      return scope.all if user.system_admin?

      # Regular users can moderate submissions in feeds belonging to groups they're members of
      group_ids = user.memberships.pluck(:group_id)
      scope.joins(:feed).where(feeds: { group_id: group_ids })
    end
  end

  def index?
    # Everyone can view the list
    true
  end

  # Can the user view the pending moderation queue?
  def pending?
    user.present?
  end

  # Can the user moderate this submission?
  def moderate?
    system_admin_only || can_moderate?
  end

  def permitted_attributes_for_moderation
    [ :moderation_status, :moderation_reason ]
  end

  private

  # Users can moderate submissions in feeds belonging to groups they're members of
  def can_moderate?
    return false unless user
    return false if record.is_a?(Class)

    group = record.feed&.group
    return false unless group

    user.memberships.exists?(group: group)
  end
end

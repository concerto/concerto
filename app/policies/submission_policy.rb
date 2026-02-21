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
  # True for system admins and members of any group that manages a feed.
  def pending?
    return false unless user
    return true if user.system_admin?

    user.groups.joins(:feeds).exists?
  end

  # Can the user moderate this submission?
  def moderate?
    system_admin_only || can_moderate?
  end

  # Returns submissions visible to the user on a content show page.
  def self.visible_submissions(user, content)
    submissions = content.submissions.includes(feed: :group)

    return submissions if user&.system_admin?
    return submissions if user && content.user_id == user.id

    if user
      group_ids = user.memberships.pluck(:group_id)
      submissions.joins(:feed).where(
        "submissions.moderation_status = ? OR feeds.group_id IN (?)",
        Submission.moderation_statuses[:approved], group_ids
      )
    else
      submissions.approved
    end
  end

  # Whether the user can see a submission's moderation reason.
  # Visible to: system admins, the content owner, or members of the feed's group.
  def show_reason?
    user && (user.system_admin? || record.content.user_id == user.id || user.memberships.exists?(group: record.feed.group))
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

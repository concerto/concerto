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

  def show?
    # Everyone can view individual submissions
    true
  end

  def new?
    super || can_create_submission?
  end

  def create?
    super || can_create_submission?
  end

  def edit?
    super || can_moderate?
  end

  def update?
    super || can_moderate?
  end

  def destroy?
    super || can_destroy_submission?
  end

  # Can the user view the pending moderation queue?
  def pending?
    user.present?
  end

  # Can the user moderate this submission?
  def moderate?
    system_admin_only || can_moderate?
  end

  def permitted_attributes
    [ :content_id, :feed_id ]
  end

  def permitted_attributes_for_moderation
    [ :moderation_status, :moderation_reason ]
  end

  private

  # Only the owner of a piece of content can create a submission
  def can_create_submission?
    return false unless user
    # For class-level checks (e.g., policy(Submission).create?), allow signed-in users
    return true if record.is_a?(Class)
    # For new records without content selected yet, allow signed-in users to access the form
    return true if record.new_record? && record.content.nil?
    # For instance-level checks with content, verify content ownership
    record.content&.user_id == user.id
  end

  # Submissions may be deleted by the owner of the piece of content
  def can_destroy_submission?
    return false unless user
    record.content.user_id == user.id
  end

  # Users can moderate submissions in feeds belonging to groups they're members of
  def can_moderate?
    return false unless user
    return false if record.is_a?(Class)

    group = record.feed&.group
    return false unless group

    user.memberships.exists?(group: group)
  end
end

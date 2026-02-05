class Submission < ApplicationRecord
  belongs_to :content
  belongs_to :feed
  belongs_to :moderator, class_name: "User", optional: true

  enum :moderation_status, { pending: 0, approved: 1, rejected: 2 }

  before_create :set_initial_moderation_status

  # Moderate a submission with a status and optional reason
  def moderate!(status:, moderator:, reason: nil)
    update!(
      moderation_status: status,
      moderator: moderator,
      moderation_reason: reason,
      moderated_at: Time.current
    )
  end

  # Re-evaluate moderation status when content is edited
  # Substantive content changes require re-moderation, even for human-approved submissions
  def reevaluate_moderation!
    if should_auto_approve?
      update!(moderation_status: :approved, moderated_at: Time.current)
    else
      update!(moderation_status: :pending, moderator: nil, moderation_reason: nil, moderated_at: nil)
    end
  end

  # Determine if this submission should be auto-approved
  def should_auto_approve?
    # Auto-approve if feed auto-approves (RSS, Remote feeds)
    return true if feed.auto_approves_submissions?

    # Auto-approve if content owner is a member of the feed's group
    return true if content.user && feed.group.memberships.exists?(user: content.user)

    false
  end

  private

  def set_initial_moderation_status
    self.moderation_status = should_auto_approve? ? :approved : :pending
    self.moderated_at = Time.current if approved?
  end
end

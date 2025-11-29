class SubmissionPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    # All users (including anonymous) can see all submissions
    def resolve
      scope.all
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
    # Submissions cannot be updated yet (reserved for future moderation)
    super
  end

  def update?
    # Submissions cannot be updated yet (reserved for future moderation)
    super
  end

  def destroy?
    super || can_destroy_submission?
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
end

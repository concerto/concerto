module SubmissionsHelper
  def moderation_status_badge(submission)
    case submission.moderation_status
    when "pending"
      content_tag(:span, "Pending",
        class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-warning/20 text-warning-dark")
    when "approved"
      content_tag(:span, "Approved",
        class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-success/20 text-success-dark")
    when "rejected"
      content_tag(:span, "Rejected",
        class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-error/20 text-error-dark")
    end
  end

  def pending_moderation_count
    return 0 unless current_user

    SubmissionPolicy::ModerationScope.new(current_user, Submission).resolve.pending.count
  end
end

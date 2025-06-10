class ContentPolicy < ApplicationPolicy
  def create?
    # If no feed_ids are provided, allow the creation
    return true unless record.feed_ids.present?

    # Check if all selected feeds have active_for_upload? as true
    record.feeds.all? { |feed| feed.active_for_upload? }
  end
end

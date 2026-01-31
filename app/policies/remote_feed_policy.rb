# frozen_string_literal: true

# RemoteFeedPolicy extends FeedPolicy with RemoteFeed-specific authorization.
#
# Key difference from FeedPolicy:
# - The URL may contain sensitive information (API keys, tokens) and is only
#   visible to users who have edit permissions on the feed.
class RemoteFeedPolicy < FeedPolicy
  # Returns attributes that are safe to display in the show view.
  # The URL is only included if the user has edit permissions, since it may
  # contain sensitive information like API keys or authentication tokens.
  def permitted_attributes_for_show
    attrs = [ :id, :name, :description, :type, :group_id, :created_at, :updated_at, :last_refreshed ]
    attrs << :url if edit?
    attrs
  end
end

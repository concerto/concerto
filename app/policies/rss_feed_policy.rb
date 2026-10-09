# frozen_string_literal: true

# RssFeedPolicy extends FeedPolicy with RssFeed-specific authorization.
#
# Key difference from FeedPolicy:
# - The URL may contain sensitive information (API keys, tokens) and is only
#   visible to users who have edit permissions on the feed. Mirrors
#   RemoteFeedPolicy, which already does this for the sibling feed type --
#   RssFeed had no equivalent gate at all, so its source URL (and anything
#   embedded in it) was shown to every viewer, including anonymous ones,
#   via rss_feeds/show.html.erb and the generic feeds/_feed.json.jbuilder
#   partial (CWE-200).
class RssFeedPolicy < FeedPolicy
  # Returns attributes that are safe to display in the show view.
  # The URL is only included if the user has edit permissions, since it may
  # contain sensitive information like API keys or authentication tokens.
  def permitted_attributes_for_show
    attrs = [ :id, :name, :description, :type, :group_id, :created_at, :updated_at, :last_refreshed, :formatter ]
    attrs << :url if edit?
    attrs
  end
end

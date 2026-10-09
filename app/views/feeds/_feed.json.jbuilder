json.extract! feed, :id, :type, :name, :description, :created_at, :updated_at
json.url feed_url(feed, format: :json)

# `config` holds each feed subtype's own source URL (RemoteFeed/RssFeed),
# which may embed an API key or token. This partial is shared by every feed
# type via /feeds.json and /feeds/:id.json, so it must defer to the same
# per-type permission gate the dedicated remote_feeds/rss_feeds show views
# already use, rather than exposing `config` unconditionally (CWE-200).
if policy(feed).permitted_attributes_for_show.include?(:url)
  json.config feed.config
end

json.extract! @rss_feed, :id, :type, :name, :description, :created_at, :updated_at
json.url rss_feed_url(@rss_feed, format: :json)

# Only include config (which contains the URL) if user has edit permissions
if policy(@rss_feed).permitted_attributes_for_show.include?(:url)
  json.config @rss_feed.config
end

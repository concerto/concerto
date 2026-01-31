json.extract! @remote_feed, :id, :type, :name, :description, :created_at, :updated_at
json.url remote_feed_url(@remote_feed, format: :json)

# Only include config (which contains the URL) if user has edit permissions
if policy(@remote_feed).permitted_attributes_for_show.include?(:url)
  json.config @remote_feed.config
end

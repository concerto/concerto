json.extract! feed, :id, :type, :name, :description, :created_at, :updated_at
# RemoteFeed config contains its URL, which may include secret API keys/tokens;
# only expose it to users authorized by RemoteFeedPolicy#permitted_attributes_for_show.
if !feed.is_a?(RemoteFeed) || policy(feed).permitted_attributes_for_show.include?(:url)
  json.config feed.config
end
json.url feed_url(feed, format: :json)

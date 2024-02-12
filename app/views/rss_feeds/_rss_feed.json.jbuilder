json.extract! rss_feed, :id, :name, :description, :url, :created_at, :updated_at
json.url rss_feed_url(rss_feed, format: :json)

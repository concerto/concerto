json.extract! feed, :id, :type, :name, :description, :config, :created_at, :updated_at
json.url feed_url(feed, format: :json)

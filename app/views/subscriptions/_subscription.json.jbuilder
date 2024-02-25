json.extract! subscription, :id, :screen_id, :field_id, :feed_id, :created_at, :updated_at
json.url subscription_url(subscription, format: :json)

json.extract! subscription, :id, :screen_id, :field_id, :feed_id, :weight, :created_at, :updated_at
json.url screen_subscriptions_url(subscription.screen_id, format: :json)

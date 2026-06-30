json.extract! iframe, :id, :name, :duration, :start_time, :end_time, :url, :created_at, :updated_at
json.url iframe_url(iframe, format: :json)

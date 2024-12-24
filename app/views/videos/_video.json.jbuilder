json.extract! video, :id, :name, :duration, :start_time, :end_time, :url, :created_at, :updated_at
json.url video_url(video, format: :json)

json.extract! clock, :id, :name, :duration, :start_time, :end_time, :format, :created_at, :updated_at
json.url clock_url(clock, format: :json)

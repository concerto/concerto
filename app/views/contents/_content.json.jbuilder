json.extract! content, :id, :name, :duration, :start_time, :end_time, :subtype_id, :subtype_type, :created_at, :updated_at
json.url content_url(content, format: :json)

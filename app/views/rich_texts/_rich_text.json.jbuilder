json.extract! rich_text, :id, :name, :duration, :start_time, :end_time, :text, :created_at, :updated_at
json.url rich_text_url(rich_text, format: :json)

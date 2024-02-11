json.extract! graphic, :id, :name, :duration, :start_time, :end_time, :image, :created_at, :updated_at
json.url graphic_url(graphic, format: :json)
json.image url_for(graphic.image)

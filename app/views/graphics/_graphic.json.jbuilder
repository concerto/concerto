json.extract! graphic, :id, :image, :created_at, :updated_at
json.url graphic_url(graphic, format: :json)
json.image url_for(graphic.image)

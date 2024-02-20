json.extract! template, :id, :name, :author, :image, :created_at, :updated_at
json.url template_url(template, format: :json)
json.image url_for(template.image)

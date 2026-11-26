json.extract! template, :id, :name, :author, :created_at, :updated_at
json.image template.image.attached? ? url_for(template.image) : nil
json.url template_url(template, format: :json)

json.extract! text_blob, :id, :body, :render_as, :created_at, :updated_at
json.url text_blob_url(text_blob, format: :json)

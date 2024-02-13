json.extract! submission, :id, :content_id, :feed_id, :created_at, :updated_at
json.url submission_url(submission, format: :json)

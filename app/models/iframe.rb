require "uri"

class Iframe < Content
  store_accessor :config, :url

  validates :url, presence: true
  validate :url_must_be_http

  def as_json(options = {})
    super(options).merge({ url: url })
  end

  def searchable_data
    { name: name, body: url.to_s }
  end

  private

  # Only allow absolute http(s) URLs so the player never embeds a javascript:,
  # data:, or otherwise unexpected scheme in the iframe src.
  def url_must_be_http
    return if url.blank?

    uri = URI.parse(url)
    unless uri.is_a?(URI::HTTP) && uri.host.present?
      errors.add(:url, "must be a valid http or https URL")
    end
  rescue URI::InvalidURIError
    errors.add(:url, "is not a valid URL")
  end
end

class TextContent < Content
  # Validations
  validates :duration, numericality: { greater_than: 0 }
  validates :data, presence: true

  # make sure the data only contains authorized html tags
  def sanitize_html
    self.data = self.class.clean_html(self.data) unless self.data.nil?
  end

  # if markdown text is present in ticker, it will be converted to html
  # and cleaned before it is saved
  def process_markdown
    self.data = self.class.convert_markdown(self.data)
    sanitize_html
  end

  def self.convert_markdown(s)
    md = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    md.render(s)
  end

  # clear out the unapproved html tags
  def self.clean_html(html)
    # sanitize gem erased '<<<'' whereas ActionView's was more discerning
    ActionController::Base.helpers.sanitize(html,
      tags: %w(h1 h2 h3 h4 div b br i em li ol u ul p q small strong),
      attributes: %w(style class)) unless html.nil?
  end

  # return the cleaned input data
  def self.preview(data)
    clean_html(convert_markdown(data.to_s))
  end

  # Ticker Text also accepts the kind because the user can change it to HtmlText
  def self.form_attributes
    attributes = super()
    attributes.concat([:kind_id])
  end
end

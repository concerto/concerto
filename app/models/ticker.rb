class Ticker < Content
  DISPLAY_NAME = 'Text'
 
  after_initialize :set_kind
  before_save :process_markdown, :alter_type
 
  # Validations
  validates :duration, :numericality => { :greater_than => 0 }
  validates :data, :presence => true
  
  # Automatically set the kind for the content
  # if it is new.
  def set_kind
    return unless new_record?
    self.kind = Kind.where(:name => 'Ticker').first
  end
 
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
 
  # if the user has specified that the kind should be text then change the type
  # so this is just like an HtmlText content item instead of a Ticker content item
  def alter_type
    if self.kind == Kind.where(:name => 'Text').first
      self.type = 'HtmlText'
    end
  end

  def self.convert_markdown(s)
    md = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    md.render(s)
  end

  # clear out the unapproved html tags
  def self.clean_html(html)
    # sanitize gem erased '<<<'' whereas ActionView's was more discerning
    ActionController::Base.helpers.sanitize(html, 
      :tags => %w(h1 h2 h3 h4 div b br i em li ol u ul p q small strong), 
      :attributes => %w(style class)) unless html.nil?
  end
 
  # return the cleaned input data
  def self.preview(data)
    clean_html(convert_markdown(data.to_s))
  end

  # Ticker Text also accepts the kind because the user can change it to HtmlText
  def self.form_attributes
    attributes = super()
    attributes.concat([:kind])
  end
 
end

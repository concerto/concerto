class Ticker < Content
  include ActionView::Helpers

  DISPLAY_NAME = 'Ticker Text'
 
  after_initialize :set_kind
  before_save :sanitize_html

  # Validations
  validates :duration, :numericality => { :greater_than => 0 }
  validates :data, :presence => true
  
  # Automatically set the kind for the content
  # if it is new.
  def set_kind
    return unless new_record?
    self.kind = Kind.where(:name => 'Ticker').first
  end

  def sanitize_html
    self.data = clean_html(self.data) unless self.data.nil?
  end

  def clean_html(html)
    # sanitize gem erased '<<<'' whereas ActionView's was more discerning
    sanitize html, :tags => %w(b br i em li ol u ul p q small strong), 
      :attributes => %w(style class) unless html.nil?
  end
end

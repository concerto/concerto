class Ticker < Content
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

  # make sure the data only contains authorized html tags
  def sanitize_html
    self.data = self.class.clean_html(self.data) unless self.data.nil?
  end

  # clear out the unapproved html tags
  def self.clean_html(html)
    # sanitize gem erased '<<<'' whereas ActionView's was more discerning
    ActionController::Base.helpers.sanitize(html, :tags => %w(b br i em li ol u ul p q small strong), :attributes => %w(style class)) unless html.nil?
  end

  # return the cleaned input data
  def self.preview(data)
    clean_html(data.to_s)
  end
end

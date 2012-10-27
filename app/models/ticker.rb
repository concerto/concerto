class Ticker < Content

  DISPLAY_NAME = 'Ticker Text'
 
  after_initialize :set_kind

  #Validations
  validates :duration, :numericality => { :greater_than => 0 }
  validates :data, :presence => true
  
  # Automatically set the kind for the content
  # if it is new.
  def set_kind
    return unless new_record?
    self.kind = Kind.where(:name => 'Ticker').first
  end

end

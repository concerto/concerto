class TimeDisplay < Content

  DISPLAY_NAME = 'Time'
 
  after_initialize :set_kind

  #Validations
  validates :duration, :numericality => { :greater_than => 0 }
  
  # Automatically set the kind for the content
  # if it is new.
  def set_kind
    return unless new_record?
    self.kind = Kind.where(:name => 'Text').first
  end

end

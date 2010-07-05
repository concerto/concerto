class Graphic < Content

  after_initialize :set_kind

  #Validations
  validates :duration, :numericality => { :greater_than => 0 }
  validates :medias, :length => { :minimum => 1, :too_short => "At least 1 file is required." }
  
  # Automatically set the kind for the content
  # if it is new.
  def set_kind
    return unless new_record?
    self.kind = Kind.where(:name => 'Graphics').first
  end

end

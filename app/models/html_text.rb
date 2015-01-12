class HtmlText < Content

  after_initialize :set_kind

  # Validations
  validates :duration, :numericality => { :greater_than => 0 }
  validates :data, :presence => true

  # Automatically set the kind for the content
  # if it is new.
  def set_kind
    return unless (new_record? && self.kind.nil?)
    self.kind = Kind.where(:name => 'Text').first
  end
end

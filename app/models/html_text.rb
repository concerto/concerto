class HtmlText < TextContent

  after_initialize :set_kind
  before_save :alter_type

  # Automatically set the kind for the content
  # if it is new.
  def set_kind
    return unless (new_record? && self.kind.nil?)
    self.kind = Kind.where(name: 'Text').first
  end

  # if the user has specified that the kind should be text then change the type
  # so this is just like an HtmlText content item instead of a Ticker content item
  def alter_type
    if self.kind == Kind.where(name: 'Ticker').first
      self.type = 'Ticker'
    end
  end
end

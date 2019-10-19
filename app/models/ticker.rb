class Ticker < TextContent
  after_initialize :set_kind
  before_save :process_markdown, :alter_type

  # Automatically set the kind for the content
  # if it is new.
  def set_kind
    return unless new_record?
    self.kind = Kind.where(name: 'Ticker').first
  end

  # if the user has specified that the kind should be text then change the type
  # so this is just like an HtmlText content item instead of a Ticker content item
  def alter_type
    if self.kind == Kind.where(name: 'Text').first
      self.type = 'HtmlText'
    end
  end
end

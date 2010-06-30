module ContentsHelper

  CONTENT_TYPES = [Graphic, Ticker]
  
  # Expose the available content subclasses.
  # Plugins will want to add their subclass to
  # this list.
  def content_types
    CONTENT_TYPES
  end

end

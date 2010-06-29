class ApplicationController < ActionController::Base
  protect_from_forgery
  
  helper_method :content_types
  
  CONTENT_TYPES = [Graphic, Ticker]
  
  # Expose the available content subclasses.
  # Plugins will want to add their subclass to
  # this list in somehow (we'll figure that out
  # at a later commit)
    def content_types
    CONTENT_TYPES
  end
end

module SubmissionsHelper
  CONTENT_TYPES = [Graphic, Ticker]
  
  # Expose the available content subclasses.
  # Plugins will want to add their subclass to
  # this list.
  def content_types
    CONTENT_TYPES
  end
  
  # Render a piece of content.
  #
  # options[:type] controls what partial is used
  # when rendering the file.  Defaults to 
  # _render_default.html.erb (:type = 'default').
  #
  # All options set are passed to the partial in options.
  # The content object is passed in content.
  def render_content(content, options={})
    options.symbolize_keys! #All the cool kids do this
  
    options[:type] ||= 'default'
    
    render  :partial => "contents/#{content.class.to_s.underscore}/render_#{options[:type]}", 
            :locals => {:content => content, :options => options}
  end
  
end

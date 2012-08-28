module ContentsHelper  

  # Expose the available content subclasses.
  def content_types
    Concerto::Application.config.content_types
  end

  # Display the name of the content type.
  def display_name(klass)
    if (klass).const_defined?("DISPLAY_NAME") && !klass::DISPLAY_NAME.nil?
      klass::DISPLAY_NAME
    else
      klass.model_name.human
    end
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

    render_partial_if("contents/#{content.class.to_s.underscore}/render_#{options[:type]}",
                      "contents/render_#{options[:type]}",
                      {:content => content, :options => options})
  end
end

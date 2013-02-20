module ContentsHelper

  # Expose a copy of the available content subclasses.
  def content_types
    Concerto::Application.config.content_types.dup
  end

  # All the content types that are allowed on a group of feeds.
  # @param [Array<Feed>] feeds Array of feeds to find the content types from.
  # @return [Array<String>] A list of content type class names, like ["Graphic", "Ticker"].
  def allowed_content_types(feeds)
    feeds.map {|f| f.content_types.reject{|k, value| value != "1"}.keys}.flatten.uniq
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

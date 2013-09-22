module ContentsHelper

  # Expose a copy of the available content subclasses.
  def content_types
    Concerto::Application.config.content_types.dup
  end
  
  def get_available_types
    allowed_types = allowed_content_types(@feeds)
    available_types = content_types.delete_if{ |subclass| !allowed_types.include?(subclass.name)}
    available_types = available_types.sort_by do |subclass|
      (subclass.name == ConcertoConfig['default_upload_type'].titleize ? '00' : '') + subclass.display_name
    end 
  end

  # All the content types that are allowed on a group of feeds.
  # @param [Array<Feed>] feeds Array of feeds to find the content types from.
  # @return [Array<String>] A list of content type class names, like ["Graphic", "Ticker"].
  def allowed_content_types(feeds)
    return content_types if feeds.nil?
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

  def feed_markers
    markers = @content.submissions.map do |s|
      content_tag('span', {:class => 'marker-feed', 'data-feed-id' => s.id, :style => 'margin-right: 12px;'}) do
        hidden_field_tag("feed_id[#{s.feed_id}]", s.feed_id) +
        content_tag('span', :class => 'label') do
          "#{html_escape s.feed.name} #{link_to '<i class="icon-remove"></i>'.html_safe, '#'}".html_safe
        end
      end
    end
    markers.join.html_safe
  end
end

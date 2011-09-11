module ApplicationHelper

  # Generate the HTML for the standardized back buttons used 
  # in the header elements.
  def back_button(path, name = "Back", options = {})
    options[:class] ||= "button back"
    tag("div", {:class => "C-header_back"}, true) + link_to(name, path, options) + raw("</div>")
  end
  
  # Generate page titles.
  def yield_for_title(default)
    content_for?(:title) ? content_for(:title) : default
  end

end

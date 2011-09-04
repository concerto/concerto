module ApplicationHelper

  # Generate the HTML for the standardized back buttons used 
  # in the header elements.
  def back_button(path, name = "Back", options = {})
    options[:class] ||= "button back"
    tag("div", {:class => "C-header_back"}, true) + link_to(name, path, options) + raw("</div>")
  end
  
  # Generate page titles
  def yield_for_title(content_sym, default)
    output = content_for(content_sym)
    output = "#{ controller.action_name.titleize } - #{ controller.controller_name.titleize }" if output.blank?
    output
  end

end

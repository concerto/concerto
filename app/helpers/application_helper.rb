module ApplicationHelper

  def back_button(path, name = "Back", options = {})
    options[:class] ||= "button back"

    tag("div", {:class => "C-header_back"}, true) + link_to(name, path, options) + raw("</div>")
  end

end

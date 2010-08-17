module ApplicationHelper

  # Generate the HTML for the standardized back buttons used 
  # in the header elements.
  def back_button(path, name = "Back", options = {})
    options[:class] ||= "button back"
    tag("div", {:class => "C-header_back"}, true) + link_to(name, path, options) + raw("</div>")
  end

  # Figure out which class we should be using to setup the sidebar.
  # The default for no sidebar is "no" but if a sidebar is used
  # the default becomes "sm" (small) but it can be overridden by
  # setting @sidebar_class anywhere a sidebar is used.
  def sidebar_class
    if content_for?(:sidebar)
      @sidebar_class || "sm"
    else
      "no"
    end
  end

end

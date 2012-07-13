module ApplicationHelper

  # Generate the HTML for the standardized back buttons used 
  # in the header elements.
  def back_button(path, name = "Back", options = {})
    options[:class] ||= "button back"
    tag("div", {:class => "viewblock-header_back"}, true) + link_to(name, path, options) + raw("</div>")
  end
  
  # Generate page titles.
  def yield_for_title(default)
    content_for?(:title) ? content_for(:title) : default
  end

  # Render the partial at the specified path if it exists within
  # the lookup_context, otherwise render the partial specified in default.
  # Locals are passed along accordingly.
  def render_partial_if(partial, default=nil, locals={})
    if lookup_context.exists?(partial, [], true)
      render :partial => partial, :locals => locals
    elsif !default.blank?
      render :partial => default, :locals => locals
    end
  end

end

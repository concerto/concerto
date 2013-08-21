module ApplicationHelper
  
  # Generate page titles.
  def yield_for_title(default)
    content_for?(:title) ? content_for(:title) : default
  end
  
  def user_leads_a_group?
    current_user.memberships.each do |m|
      if m.level == Membership::LEVELS[:leader]
        return true
      end
    end
    return false
  end

  # Render the partial at the specified path if it exists within
  # the lookup_context, otherwise render the partial specified in default
  # if it exists.
  # Locals are passed along accordingly.
  def render_partial_if(partial, default=nil, locals={})
    if lookup_context.exists?(partial, [], true)
      render :partial => partial, :locals => locals
    elsif !default.blank?
      render :partial => default, :locals => locals
    end
  end

  # render tooltip
  def tooltip_tag(tip)
    content_tag(:i, nil, { :class => "icon-question-sign muted tooltip-basic", :data => { :tooltip_text => tip } })
  end

  # render the label and the toolip beside it (passed in the options as :tip)
  def label_tooltip(object_name, method, content_or_options = nil, options = nil)
    return label object_name, method do
      concat(content_or_options)
      concat(" ")
      concat(tooltip_tag (options[:tip])) if !options.nil? && options.has_key?(:tip) && !options[:tip].blank?
    end
  end
end

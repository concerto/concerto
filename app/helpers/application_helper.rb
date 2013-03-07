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

end

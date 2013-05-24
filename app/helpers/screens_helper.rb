module ScreensHelper

  # return screen owner as a link if they are allowed to read the owner record
  def screen_owner(screen, tip=true)
    path = ((screen.owner.is_a? Group) ? group_path(screen.owner.id) : user_path(screen.owner.id))
    if can? :read, screen.owner 
      if tip
        link_to screen.owner.name, path, :title => "#{t('.owner')}"
      else
        link_to screen.owner.name, path
      end
    else
      if tip
        "<span title='#{t('.owner')}'>#{screen.owner.name}</span>".html_safe
      else
        "<span>#{screen.owner.name}</span>".html_safe
      end
    end
  end
end

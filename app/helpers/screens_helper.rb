module ScreensHelper

  # return screen owner as a link if they are allowed to read the owner record
  def screen_owner(screen, tip=true)
    path = ((screen.owner.is_a? Group) ? group_path(screen.owner.id) : user_path(screen.owner.id))
    if can? :read, screen.owner
      if tip
        link_to screen.owner.name, path, :title => t('screens.thumbs.owner')
      else
        link_to screen.owner.name, path
      end
    else
      if tip
        content_tag :span, screen.owner.name, :title => t('screens.thumbs.owner')
      else
        content_tag :span, screen.owner.name
      end
    end
  end
end

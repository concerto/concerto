module GroupsHelper
  def member_list(group=nil)
    ordered_memberships = group.memberships.approved.order('level DESC').includes(:user).all
    member_list = ordered_memberships.map do |membership|
      member_display = String.new
      if membership.level == Membership::LEVELS[:leader]
        member_display = content_tag :i, '', {:class => 'concertocon-user-leader tooltip-basic', 'data-tooltip-tex' => t('.leader')}
      end
      if can? :read, membership.user
        member_display += link_to membership.user.name, user_path(membership.user)
      else
        member_display += membership.user.name
      end
    end
    shortened_list = member_list.take(10)
    shortened_list.push "and #{link_to "#{ordered_memberships.length - 10} more", group}" if member_list.length > 10
    shortened_list.join(', ').html_safe
  end
end

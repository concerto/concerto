module GroupsHelper
  def member_list( group = nil )
    orderedMemberships = group.memberships.approved.order('level DESC').includes(:user).all
    orderedMemberships.each_with_index do |membership, i|
      concat link_to membership.user.name, user_path(membership.user)
      concat " (leader) " if membership.level == Membership::LEVELS[:leader]
      if i == 9 && membership != orderedMemberships.last
        concat ", and "
        concat link_to "#{orderedMemberships.count - 10} more", group
        break
      elsif i != 9 && membership != orderedMemberships.last
      	concat ", "
      end
    end
  end
end

module GroupsHelper
  def member_list(group=nil)
    ordered_memberships = group.memberships.approved.order('level DESC').includes(:user).to_a
    member_list = ordered_memberships.map do |membership|
      member_display = String.new
      if membership.level == Membership::LEVELS[:leader]
        member_display = "#{content_tag(:i, '', {class: 'concertocon-user-leader tooltip-basic', 'data-tooltip-tex' => t('groups.index.leader')})} "
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

  def human_membership_level_name(level)
    case level.to_sym
      when :leader
        I18n.t('groups.manage_members.leader')
      when :regular
        I18n.t('groups.manage_members.member')
      else
        I18n.t("groups.manage_members.#{level}")
    end
  end

  def human_permission_level_name(level)
    case level.to_sym
      when :none
        I18n.t("groups.manage_members.permissions.none")
      when :subscriptions
        I18n.t("groups.manage_members.permissions.subscriptions")
      when :submissions
        I18n.t("groups.manage_members.permissions.submissions")
      when :all
        I18n.t("groups.manage_members.permissions.all")
      else
        I18n.t("groups.manage_members.permissions.#{level}")
    end
  end

  # @return [Array] Returns array with elements [human name, name] suitable for options_for_select
  def human_permission_level_names(levels)
    levels.map{|l| [human_permission_level_name(l), l]}
  end
end

module GroupsHelper
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

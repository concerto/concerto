module MembershipsHelper
  def membership_role_badge(membership)
    css_classes = "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium "
    css_classes += if membership.admin?
      "bg-brand-100 text-brand-600"
    else
      "bg-neutral-100 text-neutral-800"
    end

    content_tag(:span, membership.role.humanize, class: css_classes)
  end
end

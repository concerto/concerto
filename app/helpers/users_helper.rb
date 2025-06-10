module UsersHelper
  def user_initials(user)
    if user.first_name.present? && user.last_name.present?
      (user.first_name[0] + user.last_name[0]).upcase
    else
      user.email[0].upcase
    end
  end
end

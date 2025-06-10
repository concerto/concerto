class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :first_name, presence: true
  validates :last_name, presence: true

  def password_required?
    super && !is_system_user? # Do not require password for system user.
  end

  def email_required?
    super && !is_system_user? # System users do not require an email address.
  end

  def active_for_authentication?
    super && !is_system_user? # System users should not be allowed to login.
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def display_name
    full_name.presence || email
  end
end

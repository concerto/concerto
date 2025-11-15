class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :openid_connect ]

  validates :first_name, presence: true
  validates :last_name, presence: true

  has_many :contents, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :admin_memberships, -> { admin }, class_name: "Membership"
  has_many :admin_groups, through: :admin_memberships, source: :group

  after_create :add_to_all_users_group

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

  def self.from_omniauth(auth)
    user = where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]

      # Handle name fields based on available claims
      if auth.info.given_name.present? && auth.info.family_name.present?
        user.first_name = auth.info.given_name
        user.last_name = auth.info.family_name
      elsif auth.info.name.present?
        # Fallback to splitting full name if given_name/family_name not available
        names = auth.info.name.split
        user.first_name = names.first
        user.last_name = names.length > 1 ? names[1..-1].join(" ") : names.first
      end
    end
    user
  end

  # Check if the user is a system administrator.
  #
  # System administrators are any members of the "System Administrators" group.
  def system_admin?
    Group.system_admins_group&.member?(self)
  end

  private

  def add_to_all_users_group
    all_users_group = Group.find_or_create_by!(name: Group::REGISTERED_USERS_GROUP_NAME)

    self.groups << all_users_group unless self.groups.include?(all_users_group)
  end
end

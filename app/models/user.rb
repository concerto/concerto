class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :openid_connect ]

  validates :first_name, presence: true
  validates :last_name, presence: true

  # Registered before the has_many :memberships association so it runs
  # before the dependent: :destroy cascade — otherwise the membership-level
  # guard fires first and the user is left with a less helpful error.
  before_destroy :cannot_destroy_last_system_admin

  has_many :contents, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :admin_memberships, -> { admin }, class_name: "Membership"
  has_many :admin_groups, through: :admin_memberships, source: :group

  after_create :add_to_all_users_group
  after_create :add_to_admin_group_if_first_user

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

  # Finds or provisions a user from an OmniAuth response.
  #
  # For a brand-new identity this attempts to create a local account from the
  # provider's claims. When the provider omits information we require (see
  # #missing_omniauth_claims), the returned record is *not* persisted and its
  # errors are populated — callers must check #persisted? and surface the
  # failure rather than assuming success.
  def self.from_omniauth(auth)
    # Never look up by a blank provider/uid: password-registered users have
    # NULL provider and uid, so `where(provider: nil, uid: nil)` would match an
    # existing local account (often the first system admin) and sign the caller
    # in as them. A response without a stable subject cannot provision anyone.
    if auth&.provider.blank? || auth&.uid.blank?
      return new.tap { |user| user.errors.add(:base, "Authentication response was missing a provider or subject (uid)") }
    end

    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.assign_name_from_omniauth(auth.info)
    end
  end

  # Lists the OIDC claims that provisioning needs but the provider did not
  # supply, described the way an operator would configure them on their
  # identity provider. Returns an empty array when all required claims are
  # present (a persistence failure would then have some other cause).
  #
  # This is the actionable half of the "authenticated but not logged in"
  # story: identity providers such as CAS only release these claims once an
  # administrator maps them, so we can tell the user exactly what is missing.
  def self.missing_omniauth_claims(auth)
    info = auth&.info
    return [ "email", "name (or given_name and family_name)" ] if info.blank?

    missing = []
    missing << "email" if info.email.blank?

    # OmniAuth's InfoHash#name is *derived* — it falls back to the email address
    # when no name claim was sent — so we inspect the raw claim to report what
    # the provider actually released rather than what OmniAuth synthesized.
    raw_name = info.to_h["name"]
    has_structured_name = info.given_name.present? && info.family_name.present?
    unless raw_name.present? || has_structured_name
      missing << "name (or given_name and family_name)"
    end

    missing
  end

  # Populates first/last name from whichever name claims the provider sent,
  # preferring the structured given_name/family_name claims and falling back
  # to splitting a single name claim. Leaves the fields blank when no name
  # claim is present so validation can reject the record.
  def assign_name_from_omniauth(info)
    return if info.blank?

    if info.given_name.present? && info.family_name.present?
      self.first_name = info.given_name
      self.last_name = info.family_name
    elsif info.name.present?
      names = info.name.split
      self.first_name = names.first
      self.last_name = names.length > 1 ? names[1..-1].join(" ") : names.first
    end
  end

  # Check if the user is a system administrator.
  #
  # System administrators are any members of the "System Administrators" group.
  def system_admin?
    Group.system_admins_group&.member?(self)
  end

  # Check if the user manages any screens.
  def screen_manager?
    groups.joins(:screens).exists?
  end

  # True when this user is the only remaining member of the
  # System Administrators group. Used to block destroy paths that
  # would otherwise leave the install with no administrator.
  def last_system_admin?
    return false unless system_admin?
    Group.system_admins_group.users.where.not(id: id).none?
  end

  private

  def cannot_destroy_last_system_admin
    return unless last_system_admin?

    errors.add(:base, "Cannot delete the last user in the System Administrators group")
    throw(:abort)
  end

  def add_to_all_users_group
    all_users_group = Group.find_or_create_by!(name: Group::REGISTERED_USERS_GROUP_NAME)

    self.groups << all_users_group unless self.groups.include?(all_users_group)
  end

  # Automatically adds the first human user to the System Administrators group
  # to solve the bootstrapping problem. This ensures the initial person setting
  # up the server has the necessary permissions to configure the system.
  #
  # Note: In rare cases of simultaneous user registration, multiple users could
  # be added to the admin group. This is acceptable for bootstrapping purposes.
  def add_to_admin_group_if_first_user
    return if is_system_user?
    return unless User.where(is_system_user: [ nil, false ]).count == 1

    system_admins_group = Group.find_or_create_by!(name: Group::SYSTEM_ADMIN_GROUP_NAME)
    Membership.find_or_create_by!(user: self, group: system_admins_group) do |membership|
      membership.role = :admin
    end
  end
end

class User < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  #Newsfeed
  include PublicActivity::Common if defined? PublicActivity::Common

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable,
  # :lockable, :timeoutable and :omniauthable, :trackable
  modules = [:database_authenticatable, :recoverable, :registerable, :rememberable, :validatable]
  if ActiveRecord::Base.connection.table_exists? 'concerto_configs'
    if !ConcertoConfig[:ldap_host].blank?
      modules = [:database_authenticatable, :rememberable, :registerable]
    end
    modules << :confirmable if ConcertoConfig[:confirmable]
  end
  devise *modules
         
  before_destroy :dont_delete_last_admin
  before_create :auto_confirm

  has_many :templates, :as => :owner
  has_many :contents, :dependent => :destroy
  has_many :submissions, :foreign_key => "moderator_id"
  has_many :memberships, :dependent => :destroy
  has_many :groups, :through => :memberships
  has_many :screens, :as => :owner, :dependent => :restrict

  has_many :groups, :through => :memberships, :conditions => ["memberships.level > ?", Membership::LEVELS[:pending]]
  has_many :leading_groups, :through => :memberships, :source => :group, :conditions => {"memberships.level" => Membership::LEVELS[:leader]}

  # Validations
  validates :first_name, :presence => true
  validates_uniqueness_of :email

  scope :admin, where(:is_admin => true)

  def auto_confirm
    # set as confirmed if we are not confirming user accounts so that if that is ever turned on,
    # this new user will not be locked out
    self.confirmed_at = Time.zone.local(1824, 11, 5) if !ConcertoConfig[:confirmable]
  end
  
  #a user who isn't the last admin and owns no screens is deletable
  def is_deletable?
    self.screens.size == 0 && !is_last_admin?
  end
  
  #when we only have one user in the system who is the admin
  def is_last_admin?
    User.admin.count == 1 && self.is_admin?
  end

  #last line of defense: return false so the before_destroy validation fails
  def dont_delete_last_admin
    if is_last_admin?
      return false
    end
  end

  # A simple name, combining the first and last name
  # We should probably expand this so it doesn't look stupid
  # if people only have a first name or only have a last name
  def name
    (first_name || "") + " " + (last_name || "")
  end

  # Quickly test if a user belongs to a group (this breaks if either is nil)
  def in_group?(group)
    groups.include?(group)
  end

  # Return an array of all the feeds a user owns.
  def owned_feeds
    leading_groups.collect{|g| g.feeds}.flatten
  end
  
  # Return an array of all the groups a user has a certain regular permission for.
  def supporting_groups(type, permissions)
    supporting_groups =  groups.select{|g| g.user_has_permissions?(self, :regular, type, permissions)}
    return supporting_groups
  end

end

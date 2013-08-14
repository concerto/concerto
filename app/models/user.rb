class User < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable,
  # :lockable, :timeoutable and :omniauthable, :trackable
  modules = [:database_authenticatable, :recoverable, :registerable, :rememberable, :validatable]
  if ActiveRecord::Base.connection.table_exists? 'concerto_configs'
    modules << :confirmable if ConcertoConfig[:confirmable]
  end
  devise *modules
         
  before_destroy :check_for_last_admin

  has_many :contents
  has_many :submissions, :foreign_key => "moderator_id"
  has_many :memberships, :dependent => :destroy
  has_many :groups, :through => :memberships
  has_many :screens, :as => :owner, :dependent => :restrict

  has_many :groups, -> { where "memberships.level > ?", Membership::LEVELS[:pending]}, :through => :memberships
  has_many :leading_groups, -> { where "memberships.level" => Membership::LEVELS[:leader]}, :through => :memberships, :source => :group

  # Validations
  validates :first_name, :presence => true
  
  scope :admin, -> { where :is_admin => true }

  def check_for_last_admin
    if User.admin.count == 1 && self.is_admin?
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

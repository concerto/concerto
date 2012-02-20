class Membership < ActiveRecord::Base
  # Membership levels
  LEVELS = {
    # A pending member has not yet been accepted into a group.
    # We need to update authorization to reflect this.
    :pending => 0,
    # A regular member is a member of the group.
    :regular => 1,
    # A leader controls the group.
    :leader => 9,
  }

  belongs_to :user
  belongs_to :group

  #Validations
  validates :user, :presence => true, :associated => true
  validates :group, :presence => true, :associated => true
  validates_uniqueness_of :user_id, :scope => :group_id

  #Scoping shortcuts for leaders/regular
  scope :leader, where(:level => Membership::LEVELS[:leader], :moderation_flag => true)
  scope :regular, where(:level => Membership::LEVELS[:regular], :moderation_flag => true)

  #Scoping shortcuts for approved/denied/pending
  scope :approved, where(:moderation_flag => true)
  scope :denied, where(:moderation_flag => false)
  scope :pending, where("moderation_flag IS NULL")
  
  # Test if the membership has been approved.
  # (moderation flag is true)
  def is_approved?
    moderation_flag ? true : false
  end
  
  # Test if the membership has been denied.
  # (moderation flag is false)
  def is_denied?
    (moderation_flag == false) ? true : false
  end
  
  # Test if the membership has not yet been moderated.
  # (moderation flag is nil)
  def is_pending?
    moderation_flag.nil?
  end
  
  # A shortcut to test if a membership represents a leader
  def is_leader?
    level == Membership::LEVELS[:leader]
  end

  # Approve a user in group
  def approve()
     if update_attributes({:moderation_flag => true, :level => 1 })
       true
     else
       reload
       false
     end
  end
  
  # Deny a user in group
  def deny()
    if update_attributes({:moderation_flag => false})
      true
    else
      reload
      false
    end
  end
end

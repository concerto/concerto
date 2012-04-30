class Membership < ActiveRecord::Base
  # Membership levels
  LEVELS = {
    # A denied member is not a member of the group.
    :denied => 0,
    # A pending member has not yet been accepted into a group.
    # We need to update authorization to reflect this.
    :pending => 1,
    # A regular member is a member of the group.
    :regular => 2,
    # A leader controls the group.
    :leader => 9,
  }

  belongs_to :user
  belongs_to :group

  # Validations
  validates :user, :presence => true, :associated => true
  validates :group, :presence => true, :associated => true
  validates_uniqueness_of :user_id, :scope => :group_id

  # Scoping shortcuts for leaders/regular
  scope :leader, where(:level => Membership::LEVELS[:leader])
  scope :regular, where(:level => Membership::LEVELS[:regular])

  # Scoping shortcuts for approved/pending
  scope :approved, where(":level > Membership::LEVELS[:pending]")
  scope :pending, where(:level => Membership::LEVELS[:pending])

  # Get level name of a membership
  def level_name
    name = (Membership::LEVELS.respond_to?(:key) ?  Membership::LEVELS.key(level) :  Membership::LEVELS.index(level)).to_s
  end

  # Test if the membership has been approved.
  def is_approved?
    level > Membership::LEVELS[:pending]
  end

  # Test if the membership has been denied.
  def is_denied?
    level == Membership::LEVELS[:denied]
  end

  # Test if the membership is pending.
  def is_pending?
    level == Membership::LEVELS[:pending]
  end

  # A shortcut to test if a membership represents a leader
  def is_leader?
    level == Membership::LEVELS[:leader]
  end

  # Approve a user in group
  def approve()
     if update_attributes({:level => Membership::LEVELS[:regular]})
       true
     else
       reload
       false
     end
  end

  # Deny a user in group
  def deny()
    if update_attributes({:level => Membership::LEVELS[:denied]})
      true
    else
      reload
      false
    end
  end
end

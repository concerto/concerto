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
  scope :leader, where(:level => Membership::LEVELS[:leader])
  scope :regular, where(:level => Membership::LEVELS[:regular])

  # A shortcut to test if a membership represents a leader
  def is_leader?
    level == Membership::LEVELS[:leader]
  end
end

class Membership < ActiveRecord::Base
  # Membership levels
  LEVELS = {
    # A denied member is not a member of the group.
    :denied => 0,
    # A pending member has not yet been accepted into a group.
    # We need to update authorization to reflect this.
    :pending => 1,
    # A regular member is a member of the group with full read permission.
    :regular => 2,
    # A supporting member has limited write access to a group.
    :supporter => 5,
    # A leader controls the group.
    :leader => 9,
  }

  # Membership Permissions
  PERMISSIONS = {
    :supporter => {
      :screen => {
        :none => 0, # No screen write privledges
        :subscriptions => 3, # Can update subscriptions
        :all => 9, # Full write privledges
      },
      :feed => {
        :none => 0, # No feed write privledges
        :submissions => 3, # Can update submissions (moderate)
        :all => 9 # Full write privledges
      },
    }
  }

  after_initialize :expand_permissions
  before_save :compact_permissions

  belongs_to :user
  belongs_to :group

  # Validations
  validates :user, :presence => true, :associated => true
  validates :group, :presence => true, :associated => true
  validates_uniqueness_of :user_id, :scope => :group_id

  # Scoping shortcuts for leaders/regular
  scope :leader, where(:level => Membership::LEVELS[:leader])
  scope :regular, where(:level => Membership::LEVELS[:regular])
  scope :supporter, where(:level => Membership::LEVELS[:supporter])

  # Scoping shortcuts for approved/pending
  scope :approved, where("level > #{Membership::LEVELS[:pending]}")
  scope :pending, where(:level => Membership::LEVELS[:pending])


  attr_accessor :perms
  def expand_permissions
    self.perms =  {}
    level_sym = level_name.to_sym
    if PERMISSIONS.include?(level_sym) && !permissions.nil?
      local_perms = PERMISSIONS[level_sym]
      local_perms.each_with_index do |(key, value), index|
        if index == 0
          p_value = permissions % 10
        else
          p_value = permissions / (10**index)
          p_value = p_value % 10
        end
        type = (local_perms[key].respond_to?(:key) ? local_perms[key].key(p_value) : local_perms[key].index(p_value))
        if !type.nil?
          self.perms[key] = type
        else
          self.perms[key] = nil
        end
      end
    end
    self.perms
  end

  def compact_permissions
    level_sym = level_name.to_sym
    if PERMISSIONS.include?(level_sym)
      local_perms = PERMISSIONS[level_sym]
      new_permissions = 0
      local_perms.each_with_index do |(key, value), index|
        p_value = 0
        if perms.include?(key)
          p_sym = perms[key].to_sym
          p_value = local_perms[key][p_sym]
         end
        if index == 0
          if !p_value.nil?
            new_permissions = p_value
          else
            new_permissions = 0
          end
        else
          new_permissions += p_value * (10**index)
        end
      end
      self.permissions = new_permissions
    end
  end

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

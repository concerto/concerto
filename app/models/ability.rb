class Ability
  include CanCan::Ability

  def initialize(accessor)
    # By default we assume we're working with an user
    # that doesn't have an account or anything.
    accessor ||= User.new

    # Anything real can read a user
    can :read, User if accessor.persisted?
    
    # Anything can read a viewable feed
    # the ability to 'read' a feed implies that
    # you can browse it's contents as well
    can :read, Feed, :is_viewable => true

    # Group leaders are public, anyone can view them.
    can :read, Membership, :level => Membership::LEVELS[:leader]

    # Load abilities based on the type of object.
    # We should do this at the bottom to make sure to 
    # override any generic attributes we assigned above.
    type = accessor.class.to_s.downcase + "_abilities"
    if respond_to?(type.to_sym)
      send(type.to_sym, accessor)
    end
  end

  # Permissions we grant users
  def user_abilities(user)

    # An admin can do anything
    if user.is_admin?
      can :manage, :all
    end
    
    # A user can do anything to themselves.
    can [:read, :update], User, :id => user.id
 
    # An unauthenticated user can create a new user
    can :create, User unless user.persisted?

    # An authenticated user can create stuff
    can :create, Content if user.persisted?
    can :create, Screen if user.persisted?

    # An authenticated user can submit content
    can :submit, Feed, :is_submittable => true if user.persisted?

    # If a user is part of the group, they can always
    # read and submit content to the feed.
    can [:read, :submit],  Feed do |feed|
      feed.group.users.include?(user)
    end

    # A group leader can manage all memberships
    # that belong to their group.
    can :manage, Membership do |membership|
      membership.group.leaders.include?(user)
    end

    # Regular users can only create pending memberships.
    can :create, Membership do |membership|
      user.persisted? && membership.level == Membership::LEVELS[:pending]
    end
  end

  # Permission we grant screens
  def screen_abilities(screen)
  
    # If a screen is owned by the same group as the feed
    # it can see content.
    can :read, Feed do |feed|
      if screen.owner.is_a?(Group)
        screen.owner == feed.group
      elsif screen.owner.is_a?(User)
        feed.group.users.include?(screen.owner)
      end
    end
  end

end

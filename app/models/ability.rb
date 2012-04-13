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

    # An admin user can do anything
    if user.is_admin?
      can :manage, :all
    end
    
    ## Users
    # A user can read and update themselves.
    can [:read, :update], User, :id => user.id
    # An unauthenticated user can create a new user
    can :create, User unless user.persisted?

    ## Content
    # Authenticated users can create content
    can :create, Content if user.persisted?
    # Users can update and delete their own content
    can [:update, :delete], Content, :user_id => user.id

    ## Screens
    # Authenticated users can create screens
    can :create, Screen if user.persisted?
    # Anyone can read public screens
    can :read, Screen, :is_public => true
    # Users can read, update and delete their own screens
    can [:read, :update, :delete], Screen do |screen|
      screen.owner.is_a?(User) && screen.owner == user
    end
    # Users can read group screens
    can :read, Screen do |screen|
      screen.owner.is_a?(Group) && screen.owner.include?(user)
    end
    # Group leaders can create / delete their group screens
    can [:update, :delete], Screen do |screen|
      screen.owner.is_a?(Group) && screen.owner.leaders.include?(user)
    end

    ## Submissions
    # An authenticated user can create a submission if
    # the feed is submittable or they are a member of the group.
    can :create, Submission, :feed => {:is_submittable => true} if user.persisted?
    can :create, Submission, :feed => {:group => {:id => user.group_ids }}
    # Users can delete and update their own submissions
    can [:update, :delete], Submission, :content => {:user => {:id => user.id }}
    # Submissions can be updated by moderators
    can :update, Submission do |submission|
      submission.feed.group.leaders.include?(user)
    end

    ## Feeds
    # A feed can be read if it's viewable
    can :read, Feed, :is_viewable => true
    # Group members can read a feed they own
    can :read, Feed, :group => {:id => user.group_ids }
    # Group leaders can update / date a feed they own
    can [:update, :delete], Feed do |feed|
      feed.group.leaders.include?(user)
    end

    ## Memberships
    # A group leader can manage all memberships
    # that belong to their group.
    can :manage, Membership do |membership|
      membership.group.leaders.include?(user)
    end
    # Regular users can only create pending memberships.
    can :create, Membership do |membership|
      user.persisted? && membership.level == Membership::LEVELS[:pending]
    end
    # Users can delete their own memberships.
    can :destroy, Membership, :user => user
    # Group members can read all other memberships
    can :read, Membership, :group => {:id => user.group_ids}

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

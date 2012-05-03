class Ability
  include CanCan::Ability

  def initialize(accessor)
    # By default we assume we're working with an user
    # that doesn't have an account or anything.
    accessor ||= User.new

    ## Users
    # Anything real can read a user
    can :read, User if accessor.persisted?
    
    ## Feeds
    # Anything can read a viewable feed
    # the ability to 'read' a feed implies that
    # you can browse it's contents as well
    can :read, Feed, :is_viewable => true
    #TODO Content permissions per #78
    can :read, Content if true

    ## Fields
    # Anything can read fields and positions.
    # Only admin users can edit them.
    can :read, Field

    ## Positions
    can :read, Position

    ## Membership
    # Group leaders are public, anyone can view them.
    can :read, Membership, :level => Membership::LEVELS[:leader]

    ## Groups
    # Groups are only public if something they manage is viewable.
    can :read, Group do |group|
      group.feeds.where(:is_submittable => true).exists? || group.feeds.where(:is_viewable => true).exists?
    end
    can :read, Group do |group|
      group.screens.where(:is_public => true).exists?
    end

    ## Templates
    # Oddly enough, templates store a hidden flag instead of public
    # like everything else.
    can :read, Template, :is_hidden => false

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
    
    #Subscriptions
    #Only the owning group or user can manage screen subscriptions
    can :manage, Subscription, :screen => { :owner_id => user.id}
    
    # Users can read group screens
    can :read, Screen do |screen|
      screen.owner.is_a?(Group) && screen.owner.users.include?(user)
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
    # Users can read, delete and update their own submissions.
    can [:read, :update, :delete], Submission, :content => {:user => {:id => user.id }}
    # Submissions can be read and updated by moderators.
    can [:read, :update], Submission do |submission|
      submission.feed.group.leaders.include?(user)
    end
    # Approved submissions can be read if their feed is public of the user is a member
    # of the feeds group.
    can :read, Submission do |s|
      s.moderation_flag && (s.feed.is_viewable || s.feed.group.users.include?(user))
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

    ## Groups
    # A group member can read their group
    can :read, Group, :id => user.group_ids
    # Group leaders can edit the group
    can :update, Group do |group|
      group.leaders.include?(user)
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

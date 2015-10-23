class Ability
  include CanCan::Ability

  def initialize(accessor)
    # By default we assume we're working with an user
    # that doesn't have an account or anything.
    accessor ||= User.new

    ## Users
    # Anything real can read a user
    can :read, User if accessor.persisted?

    ## Content
    # If any of the submissions can be read the content can be read too.
    can :read, Content do |content|
      content.submissions.any? { |s| can?(:read, s) }
    end

    # Only define these permissive settings if concerto is set to be public
    if ConcertoConfig[:public_concerto]
      ## Users
      # A user is readable by the public if the user has
      # public content or public screens.
      can :read, User, screens: {is_public: true}
      can :read, User, contents: {submissions: {feed: {is_viewable: true}, moderation_flag: true}}

      ## Feeds
      # Anything can read a viewable feed
      # the ability to 'read' a feed implies that
      # you can browse it's contents as well
      can :read, Feed, is_viewable: true

      ## Content
      # Content approved on public feeds is publcally accessible.
      can :read, Content, submissions: {feed: {is_viewable: true}, moderation_flag: true}

      ## Fields
      # Anything can read fields and positions.
      # Only admin users can edit them.
      can :read, Field

      ## Positions
      can :read, Position

      ## Membership
      # Group leaders are public, anyone can view them.
      can :read, Membership, level: Membership::LEVELS[:leader]

      ## Groups
      # Groups are only public if something they manage is viewable.
      can :read, Group, feeds: {is_submittable: true}
      can :read, Group, feeds: {is_viewable: true}
      can :read, Group, screens: {is_public: true}

      ## Templates
      # Oddly enough, templates store a hidden flag instead of public
      # like everything else.
      can [:read, :preview], Template, is_hidden: false
    end

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
    can [:read, :update], User, id: user.id
    # An unauthenticated user can create a new user, if that's allowed globally
    if ConcertoConfig[:allow_registration]
      can :create, User unless user.persisted?
    end

    # The User#index action requires a special setup.
    # By default, all the :read checks will pass because any
    # user can read at least 1 user.  We use this custom
    # action to only let admins access the user list.
    can :list, User if user.is_admin?

    # If a third party authentication system is in use, we don't want anyone
    # creating users
    if Rails.application.config.middleware.include? "OmniAuth::Builder"
      cannot :create, User
    end

    #users can view pages (which are created by admins)
    can :read, Page

    ## Content
    # Authenticated users can create content
    can :create, Content if user.persisted?
    # Users can read and update and delete their own content
    can [:read, :delete], Content, user_id: user.id
    can :update, Content do |content|
      (content.is_approved? == false && content.user_id == user.id) ||
        # users can resubmit their expired content
        (content.is_expired? && content.user_id == user.id)
    end

    ## Screens

    # Users can list visible screen
    can :list, Screen

    # Authenticated users can create screens
    if ConcertoConfig[:allow_user_screen_creation]
      can :create, Screen, owner_type: 'User', owner_id: user.id
      can :create, Screen do |screen|
        screen.owner.is_a?(Group) && (screen.owner.leaders.include?(user) ||
          screen.owner.user_has_permissions?(user, :regular, :screen, [:all]))
      end
    end
    # Anyone can read public screens
    can :read, Screen, is_public: true if (user.persisted? || ConcertoConfig[:public_concerto])
    # Users can read, update and delete their own screens
    can [:read, :preview, :update, :delete], Screen, owner_type: 'User', owner_id: user.id

    # Users can read group screens
    can :read, Screen, owner_type: 'Group', owner_id: user.group_ids

    # Group leaders can create / delete their group screens.
    # So can special supporters
    can [:update, :delete, :preview], Screen do |screen|
      screen.owner.is_a?(Group) && (screen.owner.leaders.include?(user) ||
        screen.owner.user_has_permissions?(user, :regular, :screen, [:all]))
    end

    ## Template Preview
    can [:preview], Template, is_hidden: false

    ## FieldConfig
    # Only the owning group or user can manage a screen's field configs.
    can :manage, FieldConfig, screen: {owner_id: user.id, owner_type: 'User'}
    can :manage, FieldConfig do |field_config|
      screen = field_config.screen
      unless screen.nil?
        screen.owner.is_a?(Group) && (screen.owner.leaders.include?(user) ||
          screen.owner.user_has_permissions?(user, :regular, :screen, [:all]))
      end
    end

    ## Subscriptions
    # Only the owning group or user can manage screen subscriptions
    can :manage, Subscription, screen: {owner_id: user.id, owner_type: 'User'}
    can :manage, Subscription do |subscription|
      screen = subscription.screen
      screen.owner.is_a?(Group) && (screen.owner.leaders.include?(user) ||
        screen.owner.user_has_permissions?(user, :regular, :screen, [:all, :subscriptions]))
    end

    ## Submissions
    # An authenticated user can create a submission if
    # the feed is submittable or they are a member of the group.
    can :create, Submission, feed: {is_submittable: true} if user.persisted?
    can :create, Submission, feed: {group: {id: user.group_ids}}
    # Users can read and delete their own submissions.
    can [:read, :delete], Submission, content: {user: {id: user.id}}
    # Submissions can be read and updated by moderators.
    can [:read, :update], Submission do |submission|
      (submission.feed.group.leaders.include?(user) ||
        submission.feed.group.user_has_permissions?(user, :regular, :feed, [:all, :submissions]))
    end
    # Approved submissions can be read if they can read the feed.
    can :read, Submission do |s|
      s.moderation_flag && can?(:read, s.feed)
    end

    ## Media
    # Any authenticated user can create a submission if
    can :create, Media if user.persisted?

    ## Feeds
    # A feed can be read if it's viewable
    can :read, Feed, is_viewable: true if (user.persisted? || ConcertoConfig[:public_concerto])
    # Group members can read a feed they own
    can :read, Feed, group: {id: user.group_ids}
    # Group leaders can update / date a feed they own
    can [:update, :delete], Feed do |feed|
      (feed.group.leaders.include?(user) ||
        feed.group.user_has_permissions?(user, :regular, :feed, [:all]))
    end
    # A group leader or supporter can create feeds
    if ConcertoConfig[:allow_user_feed_creation]
      if user.leading_groups.any? || user.supporting_groups(:feed, [:all]).any?
        can :create, Feed do |feed|
          if !feed.group.nil?
            (user.leading_groups.include?(feed.group) ||
              user.supporting_groups(:feed, [:all]).include?(feed.group))
          else
            true
          end
        end
      end
    end

    # Create custom submit rules by coping submission creation rules
    relevant_rules(:create, Submission).each do |rule|
      can :submit_content, Feed, rule.conditions[:feed]
    end

    ## Memberships
    # A group leader can manage all memberships
    # that belong to their group.
    can :manage, Membership do |membership|
      membership.group.leaders.include?(user)
    end
    # Regular users can only create pending memberships.
    can :create, Membership, level: Membership::LEVELS[:pending], user: user if user.persisted?
    # Users can delete their own memberships.
    can :delete, Membership, user: user
    # Group members can read all other memberships
    can :read, Membership, group: {id: user.group_ids}

    ## Groups

    # User can list visible groups
    can :list, Group

    # A group member can read their group
    can :read, Group, id: user.group_ids
    # Group leaders can edit the group
    can :update, Group do |group|
      group.leaders.include?(user)
    end
  end

  # Permission we grant screens
  def screen_abilities(screen)
    ## Screens
    # A Screen can read its own properties
    can :read, Screen, id: screen.id
    # A logged-in screen can display its full frontend.
    # Note that no one else can do this, even if it is a public screen.
    can [:display, :preview], Screen, id: screen.id

    ## Feeds
    # If a screen is owned by the same group as the feed
    # it can see content, or if the feed is viewable.
    can :read, Feed, is_viewable: true
    can :read, Feed, group_id: screen.owner_id if screen.owner.is_a? Group
    can :read, Feed, group_id: screen.owner.group_ids if screen.owner.is_a? User

    # Screen must be able to read all feeds it has subscriptions for
    can :read, Feed, id: screen.subscriptions.map{|s| s.feed_id}.uniq


    ## Submissions
    # Submissions can be read if the content has been moderated,
    # the screen can read the feed, and the screen has a valid subscription
    # for that feed.
    can :read, Submission do |s|
      s.moderation_flag && can?(:read, s.feed) &&
        !screen.subscriptions.where(feed_id: s.feed).empty?
    end

    ## Content
    # Content can be read if any of the submissions can be read.
    can :read, Content do |content|
      content.submissions.any? { |s| can?(:read, s) }
    end

    ## FieldConfig
    # A screen can read any of it's FieldConfigs
    can :read, FieldConfig, screen_id: screen.id
  end
end

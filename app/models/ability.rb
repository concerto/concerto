class Ability
  include CanCan::Ability

  def initialize(accessor)
    # By default we assume we're working with an user
    # that doesn't have an account or anything.
    accessor ||= User.new

    # Load abilities based on the type of object
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
  end

end

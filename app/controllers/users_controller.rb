class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: %i[ show ]
  after_action :verify_authorized, except: [ :index ]
  after_action :verify_policy_scoped, only: [ :index ]

  # GET /users
  def index
    @users = policy_scope(User).includes(:groups).order(:email)
  end

  # GET /users/1 or /users/1.json
  def show
    authorize @user
    @memberships = @user.memberships.includes(:group).order("groups.name")
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params.expect(:id))
  end
end

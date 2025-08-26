class UsersController < ApplicationController
  before_action :set_user, only: %i[ show ]

  # GET /users/1 or /users/1.json
  def show
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params.expect(:id))
  end
end

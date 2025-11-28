class UsersController < ApplicationController
  before_action :set_user, only: %i[ show ]
  after_action :verify_authorized

  # GET /users/1 or /users/1.json
  def show
    authorize @user
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params.expect(:id))
  end
end

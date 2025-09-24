class GroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_group, only: [ :show, :edit, :update, :destroy ]

  def index
    @groups = Group.includes(:users).order(:name)
  end

  def show
    @members = @group.memberships.includes(:user).order("users.first_name, users.last_name")
    @available_users = User.where.not(id: @group.user_ids).order(:first_name, :last_name)
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)

    if @group.save
      redirect_to @group, notice: "Group was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @group.update(group_params)
      redirect_to @group, notice: "Group was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @group.destroy
      redirect_to groups_path, notice: "Group was successfully deleted."
    else
      redirect_to groups_path, alert: @group.errors.full_messages.join(", ")
    end
  end


  private

  def set_group
    @group = Group.find(params[:id])
  end

  def group_params
    params.require(:group).permit(:name, :description)
  end
end

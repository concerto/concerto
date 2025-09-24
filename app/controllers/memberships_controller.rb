class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_group
  before_action :set_membership, only: [ :update, :destroy ]

  def create
    @membership = @group.memberships.build(membership_params)

    if @membership.save
      redirect_to @group, notice: "#{@membership.user.full_name} has been added to the group."
    else
      redirect_to @group, alert: @membership.errors.full_messages.join(", ")
    end
  end

  def update
    if @membership.update(membership_params)
      redirect_to @group, notice: "#{@membership.user.full_name}'s role has been updated."
    else
      redirect_to @group, alert: @membership.errors.full_messages.join(", ")
    end
  end

  def destroy
    user_name = @membership.user.full_name

    if @membership.destroy
      redirect_to @group, notice: "#{user_name} has been removed from the group."
    else
      redirect_to @group, alert: @membership.errors.full_messages.join(", ")
    end
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_membership
    @membership = @group.memberships.find(params[:id])
  end

  def membership_params
    attrs = [ :role ]
    # Only allow user_id on new memberships.
    attrs << :user_id if action_name == "create"
    params.require(:membership).permit(*attrs)
  end
end

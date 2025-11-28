class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_group
  before_action :set_membership, only: [ :update, :destroy ]
  after_action :verify_authorized

  def create
    @membership = @group.memberships.build(membership_params)
    authorize @membership

    if @membership.save
      redirect_to @group, notice: "#{@membership.user.full_name} has been added to the group."
    else
      redirect_to @group, alert: @membership.errors.full_messages.join(", ")
    end
  end

  def update
    authorize @membership
    if @membership.update(membership_params)
      redirect_to @group, notice: "#{@membership.user.full_name}'s role has been updated."
    else
      redirect_to @group, alert: @membership.errors.full_messages.join(", ")
    end
  end

  def destroy
    authorize @membership
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
    # Use policy-based permitted attributes for dynamic strong parameters
    target_membership = @membership || @group.memberships.build
    params.require(:membership).permit(policy(target_membership).permitted_attributes)
  end
end

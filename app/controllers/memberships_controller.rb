class MembershipsController < ApplicationController
  before_filter :get_group

  def get_group
    @group = Group.find(params[:group_id])
  end

  # POST /groups/:group_id/memberships
  # POST /groups/:group_id/memberships.xml
  def create
    @membership = Membership.find_or_create_by_user_id_and_group_id(params[:membership][:user_id], params[:group_id])

    if params[:autoconfirm]
      @membership.update_attributes(:level => Membership::LEVELS[:regular])
    else
      @membership.update_attributes(:level => Membership::LEVELS[:pending])
    end

    respond_to do |format|
      if @membership.save
        format.html { redirect_to(@group, :notice => t(:membership_created)) }
        format.xml  { render :xml => @group, :status => :created, :location => @group }
      else
        format.html { redirect_to @group }
        format.xml  { render :xml => @membership.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /groups/:group_id/memberships/1
  # PUT /groups/:group_id/memberships/1.xml
  def update
    @membership = Membership.find(params[:id])

    respond_to do |format|
      if @membership.update_attributes(params[:membership])
        format.html { redirect_to(@group, :notice => t(:membership_updated)) }
        format.xml  { head :ok }
      else
        format.html { redirect_to @group }
        format.xml  { render :xml => @membership.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.xml
  def destroy
    @membership = Membership.find(params[:id])
    @membership.destroy

    respond_to do |format|
      format.html { redirect_to(@group, :notice => t(:member_removed)) }
      format.xml  { head :ok }
    end
  end

# PUT /groups/:group_id/memberships/1/approve
  def approve
    membership = Membership.find(params[:id])
    respond_to do |format|
      if membership.approve()
        format.html { redirect_to(group_path(params[:group_id]), :notice => t(:membership_approved)) }
      else
        format.html { redirect_to(group_path(params[:group_id]), :notice => t(:membership_failed_approve)) }
      end
    end
  end
  
  # PUT /groups/:group_id/memberships/1/deny
  def deny
    membership = Membership.find(params[:id])
    respond_to do |format|
      if membership.deny()
        format.html { redirect_to(group_path(params[:group_id]), :notice => t(:membersip_denied)) }
      else
        logger.debug membership.errors
        format.html { redirect_to(group_path(params[:group_id]), :notice => t(:membership_failed_deny)) }
      end
    end
  end
end

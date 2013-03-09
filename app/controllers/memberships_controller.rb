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
    
    auth!

    respond_to do |format|
      if @membership.save
        @membership.create_activity :create, :owner => @membership.user, :recipient => @membership.group, :params => {:level => @membership.level_name, :adder => current_user.id}
        format.html { redirect_to(edit_group_path(@group), :notice => t(:membership_created)) }
        format.xml { render :xml => @group, :status => :created, :location => @group }
      else
        format.html { redirect_to @group }
        format.xml { render :xml => @membership.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /groups/:group_id/memberships/1
  # PUT /groups/:group_id/memberships/1.xml
  def update
    @membership = Membership.find(params[:id])
    auth!
    respond_to do |format|
      if (@membership.can_resign_leadership?(membership_params['level'])) && (@membership.update_attributes(membership_params))
        format.html { redirect_to(edit_group_path(@group), :notice => t(:membership_updated)) }
        format.xml { head :ok }
      else
        format.html { redirect_to @group, :notice => @group.errors }
        format.xml { render :xml => @membership.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1 
  # DELETE /groups/1.xml
  def destroy
    @membership = Membership.find(params[:id])
    auth!
    respond_to do |format|
      #throw a negative one at a function expecting a membership level to indicate deletion
      if @membership.can_resign_leadership?(-1)
        @membership.create_activity :destroy, :owner => current_user, :recipient => @membership.user, :params => {:group_name => @membership.group.name}
        if @membership.destroy
          format.html { redirect_to({:controller => :groups, :action => :edit, :id => @group}, :notice => t(:member_removed)) }
          format.xml { head :ok }
        else
          format.html { redirect_to @group, :notice => t(:membership_denied) }
          format.xml { render :xml => @membership.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

# PUT /groups/:group_id/memberships/1/approve
  def approve
    membership = Membership.find(params[:id])
    auth!    
    respond_to do |format|
      if membership.approve()
        format.html { redirect_to(edit_group_path(params[:group_id]), :notice => t(:membership_approved)) }
      else
        format.html { redirect_to(edit_group_path(params[:group_id]), :notice => t(:membership_denied)) }
      end
    end
  end

# PUT /groups/:group_id/memberships/1/promote_to_leader
  def promote_to_leader
    membership = Membership.find(params[:id])
    auth!    
    respond_to do |format|
      if membership.promote_to_leader()
        format.html { redirect_to(group_path(params[:group_id]), :notice => t(:membership_approved)) }
      else
        format.html { redirect_to(group_path(params[:group_id]), :notice => t(:membership_denied)) }
      end
    end
  end

  # PUT /groups/:group_id/memberships/1/deny
  def deny
    membership = Membership.find(params[:id])
    auth!    
    respond_to do |format|
      if membership.deny()
        format.html { redirect_to(group_path(params[:group_id]), :notice => t(:membersip_denied)) }
      else
        logger.debug membership.errors
        format.html { redirect_to(group_path(params[:group_id]), :notice => t(:membership_failed_deny)) }
      end
    end
  end

  private

  def membership_params
    params.require(:membership).permit(:user_id, :group_id, :created_at, :level, :permissions, :receive_emails)
  end
end

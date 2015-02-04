class MembershipsController < ApplicationController
  before_filter :get_group

  def get_group
    @group = Group.find(params[:group_id])
  end

  # POST /groups/:group_id/memberships
  # POST /groups/:group_id/memberships.xml
  def create
    @membership = Membership.where(:user_id => params[:membership][:user_id], :group_id => params[:group_id]).first_or_create

    if params[:autoconfirm] || current_user.is_admin?
      @membership.update_attributes(:level => Membership::LEVELS[:regular])
    else
      @membership.update_attributes(:level => Membership::LEVELS[:pending])
    end

    @membership.perms[:screen] = params[:screen]
    @membership.perms[:feed] = params[:feed]

    auth!

    respond_to do |format|
      if @membership.save
        process_notification(@membership, {}, process_notification_options({
          :params => {
            :level => @membership.level_name,
            :member_id => @membership.user.id,
            :member_name => @membership.user.name,
            :group_id => @membership.group.id,
            :group_name => @membership.group.name
          },
          :recipient => @membership.group}))
        if can? :update, @group
          format.html { redirect_to(manage_members_group_path(@group), :notice => t(:membership_created)) }
        else
          format.html { redirect_to(group_path(@group), :notice => t(:membership_applied_for)) }
        end
        format.xml { render :xml => @group, :status => :created, :location => @group }
      else
        if can? :update, @group
          format.html { redirect_to manage_members_group_path(@group) }
        else
          format.html { redirect_to group_path(@group) }
        end
        format.xml { render :xml => @membership.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /groups/:group_id/memberships/1
  # PUT /groups/:group_id/memberships/1.xml
  def update
    @membership = Membership.find(params[:id])
    action = params[:perform]
    receive_emails = params[:receive_emails]
    note = :preferences_updated
    success = true
    auth!
    respond_to do |format|
      success, note = @membership.update_membership_level(action) unless action.nil?
      @membership.receive_emails = receive_emails unless (receive_emails.nil? || !success)
      # redirect to the users page if an email preference was specified since thats the only place it can come from
      if success && @membership.save
        format.html { redirect_to (receive_emails.nil? ? manage_members_group_path(@group) : @membership.user), :notice => t(note) }
        format.xml { head :ok }
      else
        format.html { redirect_to (receive_emails.nil? ? manage_members_group_path(@group) : @membership.user), :notice => t(note) }
        format.xml { render :xml => t(note), :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.xml
  def destroy
    @membership = Membership.find(params[:id])

    auth!
    respond_to do |format|
      if @membership.destroy
              process_notification(@membership, {}, process_notification_options({
        :params => {
          :level => @membership.level_name,
          :member_id => @membership.user.id,
          :member_name => @membership.user.name,
          :group_id => @membership.group.id,
          :group_name => @membership.group.name
        },
        :recipient => @membership.user}))
        format.html { redirect_to manage_members_group_path(@group), :notice => t(:member_removed) }
        format.xml { head :ok }
      elsif !@membership.can_resign_leadership?
        format.html { redirect_to manage_members_group_path(@group), :notice => t(:leadership_removal_denied) }
        format.xml { render :xml => @membership.errors, :status => :unprocessable_entity }      
      else
        format.html { redirect_to manage_members_group_path(@group), :notice => t(:membership_denied) }
        format.xml { render :xml => @membership.errors, :status => :unprocessable_entity }
      end
    end
  end

  private
  
  def confirm_leader_is_removable
    unless can_resign_leadership?
      errors.add(:base, "The leader cannot be deleted.")
      return false
    end
  end  

  def membership_params
    params.require(:membership).permit(:user_id, :group_id, :created_at, :level, :permissions, :receive_emails)
  end
end

class MembershipsController < ApplicationController
  before_filter :get_group

  def get_group
    @group = Group.find(params[:group_id])
  end

  # POST /groups/:group_id/memberships
  # POST /groups/:group_id/memberships.xml
  def create
    @membership = Membership.where(:user_id => params[:membership][:user_id], :group_id => params[:group_id]).first_or_create

    if params[:autoconfirm]
      @membership.update_attributes(:level => Membership::LEVELS[:regular])
    else
      @membership.update_attributes(:level => Membership::LEVELS[:pending])
    end
    
    auth!

    respond_to do |format|
      if @membership.save
        process_notification(@membership, {:level => @membership.level_name, :adder => current_user.id}, :action => 'create', :owner => @membership.user, :recipient => @membership.group)
        format.html { redirect_to(@group, :notice => t(:membership_created)) }
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
        format.html { redirect_to (receive_emails.nil? ? @group : @membership.user), :notice => t(note) }
        format.xml { head :ok }
      else
        format.html { redirect_to (receive_emails.nil? ? @group : @membership.user), :notice => t(note) }
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
      process_notification(@membership, {:group_name => @membership.group.name}, :action => 'destroy', :owner => current_user, :recipient => @membership.user)
      if @membership.destroy
        format.html { redirect_to @group, :notice => t(:member_removed) }
        format.xml { head :ok }
      else
        format.html { redirect_to @group, :notice => t(:membership_denied) }
        format.xml { render :xml => @membership.errors, :status => :unprocessable_entity }
      end
    end
  end

  private

  def membership_params
    params.require(:membership).permit(:user_id, :group_id, :created_at, :level, :permissions, :receive_emails)
  end
end

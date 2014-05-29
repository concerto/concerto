class GroupsController < ApplicationController
  respond_to :html, :json, :xml
  
  # GET /groups
  # GET /groups.xml
  def index
    @groups = Group.all
    @my_groups = current_user.nil? ? [] : current_user.groups
    @users = User.all
    auth!
    respond_with(@groups)
  end

  # GET /groups/1
  # GET /groups/1.xml
  def show
    @group = Group.find(params[:id])
    @feeds_separated = @group.feeds.in_groups(2)
    @feeds_left = @feeds_separated[0]
    @feeds_right = @feeds_separated[1]
    auth!
    respond_with(@group)
  end

  # GET /groups/new
  # GET /groups/new.xml
  def new
    @group = Group.new
    auth!
    respond_with(@group)
  end

  def manage_members
    @group = Group.find(params[:id])
    @denied = Membership.where(:group_id => params[:id], :level => 0)
    auth! :action => :edit
    respond_with(@group)
  end

  # GET /groups/1/edit
  def edit
    @group = Group.find(params[:id])
    auth!
  end

  # POST /groups
  # POST /groups.xml
  def create
    @group = Group.new(group_params)
    auth!
    if @group.save
      process_notification(@group, {}, process_notification_options({:params => {:group_name => @group.name}}))
      flash[:notice] = t(:group_created)
    end
    respond_with(@group)
  end

  # PUT /groups/1
  # PUT /groups/1.xml
  def update
    @group = Group.find(params[:id])
    auth!
    if @group.update_attributes(group_params)  
      process_notification(@group, {}, process_notification_options({:params => {:group_name => @group.name}}))
      flash[:notice] = t(:group_updated) 
    end  
    respond_with(@group)  
  end

  # DELETE /groups/1
  # DELETE /groups/1.xml
  def destroy
    @group = Group.find(params[:id])
    auth!
    #we don't let groups owning screens or feeds get deleted
    unless @group.is_deletable?
      redirect_to(@group, :notice => t(:group_not_deletable)) 
      return
    end
    
    process_notification(@group, {}, process_notification_options({:params => {:group_name => @group.name}}))
    @group.destroy

    respond_with(@group) 
  end

private

  # Restrict the allowed parameters to a select set defined in the model.
  def group_params
    params.require(:group).permit(:name, :narrative, :new_leader, :memberships_attributes => [:id, {:perms => [:screen, :feed]}])
  end
end

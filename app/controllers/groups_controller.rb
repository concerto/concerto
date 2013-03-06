class GroupsController < ApplicationController
  # GET /groups
  # GET /groups.xml
  def index
    @groups = Group.all
    @my_groups = current_user.nil? ? [] : current_user.groups
    @users = User.all
    auth!

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @groups }
    end
  end

  # GET /groups/1
  # GET /groups/1.xml
  def show
    @group = Group.find(params[:id])
    auth!

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @group }
    end
  end

  # GET /groups/new
  # GET /groups/new.xml
  def new
    @group = Group.new
    auth!

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @group }
    end
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

    respond_to do |format|
      if @group.save
        format.html { redirect_to(@group, :notice => t(:group_created)) }
        format.xml  { render :xml => @group, :status => :created, :location => @group }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.xml
  def update
    @group = Group.find(params[:id])
    auth!

    respond_to do |format|
      if @group.update_attributes(group_params)
        format.html { redirect_to(@group, :notice => t(:group_updated)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.xml
  def destroy
    @group = Group.find(params[:id])
    auth!
    @group.destroy

    respond_to do |format|
      format.html { redirect_to(groups_url) }
      format.xml  { head :ok }
    end
  end

private

  # Restrict the allowed parameters to a select set defined in the model.
  def group_params
    params.require(:group).permit(:name, :narrative, :new_leader,
                                  :memberships_attributes => [:id, {:perms => [:screen, :feed]}])
  end
end

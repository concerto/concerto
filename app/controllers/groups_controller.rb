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
  
  def bulk_update
    memberships = params["membership"]["level"]
    memberships.each do |membership_id,membership_attrs|
      membership = Membership.find(membership_id)
      membership.update_attributes(membership_attrs)
    end
    redirect_to(groups_url)
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
    @group = Group.new(params[:group])
    auth!

    respond_to do |format|
      if @group.save
        @membership = Membership.new(:group => @group, :user => current_user, :level => Membership::LEVELS[:leader])
        @membership.save
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
      if @group.update_attributes(params[:group])
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
end

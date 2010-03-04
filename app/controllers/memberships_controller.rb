class MembershipsController < ApplicationController
  # POST /groups/:group_id/memberships
  # POST /groups/:group_id/memberships.xml
  def create
    @group = Group.find(params[:group_id])
    @membership = Membership.new({:user_id => params[:membership][:user_id], :group_id => params[:group_id]})

    respond_to do |format|
      if @membership.save
        format.html { redirect_to(@group, :notice => 'User was successfully added.') }
        format.xml  { render :xml => @group, :status => :created, :location => @group }
      else
        format.html { redirect_to @group }
        format.xml  { render :xml => @membership.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # PUT /groups/:group_id/memberships/1/promote
  # PUT /groups/:group_id/memberships/1/promote.xml
  def promote
    @membership = Membership.find(params[:id])
    @membership.is_leader = true
    if @membership.save
      redirect_to(@membership.group, :notice => 'Member promoted') 
    else
      redirect_to @membership.group
    end
  end
  
  # PUT /groups/:group_id/memberships/1/demote
  # PUT /groups/:group_id/memberships/1/demote.xml
  def demote
    @membership = Membership.find(params[:id])
    @membership.is_leader = false
    if @membership.save
      redirect_to(@membership.group, :notice => 'Member demoted') 
    else
      redirect_to @membership.group
    end
  end

  # PUT /groups/:group_id/memberships/1
  # PUT /groups/:group_id/memberships/1.xml
  def update
    @group = Group.find(params[:group_id])
    @membership = Membership.find(params[:id])

    respond_to do |format|
      if @membership.update_attributes(params[:membership])
        format.html { redirect_to(@group, :notice => 'Membership was successfully updated.') }
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
    @group = Group.find(params[:group_id])
    @membership = Membership.find(params[:id])
    @membership.destroy

    respond_to do |format|
      format.html { redirect_to(@group, :notice => 'User removed') }
      format.xml  { head :ok }
    end
  end
end

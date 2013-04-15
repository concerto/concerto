class UsersController < ApplicationController
  respond_to :html, :json
   
  # GET /users
  def index
    @users = User.all
    auth!({:action => :list, :allow_empty => false, :new_exception => false})
    respond_with(@users)
  end

  # GET /users/1
  def show
    @user = User.find(params[:id])
    auth!
    @user.email = '' unless user_signed_in?

    @memberships = @user.memberships
    auth!({:action => :read, :object => @memberships})

    @contents = @user.contents.where('parent_id IS NULL')
    auth!({:action => :read, :object => @contents})

    @screens = @user.screens + @user.groups.collect{|g| g.screens}.flatten
    auth!({:action => :read, :object => @screens})
 
    respond_with(@user)
  end

  # GET /users/new
  def new
    @user = User.new
    auth!(:action => :manage)
    respond_with(@user)
  end

  # POST /users
  # POST /users.xml
  def create
    set_admin = params[:user].delete("is_admin")
    @user = User.new(params[:user])
    if !(set_admin.nil?) and can? :manage, User
      @user.is_admin = set_admin
    end
    auth!

    respond_to do |format|
      if @user.save
        format.html { redirect_to(@user, :notice => 'User was successfully created.') }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
    auth!
    respond_with(@user)  
  end
  
  # PUT /users/1
  def update
    @user = User.find(params[:id])
    auth!

    set_admin = params[:user].delete("is_admin")
    if @user.update_attributes(params[:user])
      flash[:notice] = t(:user_updated)
    end
    if !(set_admin.nil?) and can? :manage, User
      @user.update_attribute("is_admin", set_admin)
    end
    respond_with(@user)
  end

  # DELETE /users/1
  def destroy
    @user = User.find(params[:id])
    auth!

    if !@user.destroy
      flash[:notice] = t(:cannot_delete_last_admin)
    end
    respond_with(@user)
  end
  
end

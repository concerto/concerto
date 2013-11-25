class UsersController < ApplicationController
  respond_to :html, :json, :xml
   
  # GET /users
  def index
    @users = User.page(params[:page]).per(20)
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
    @contents = Kaminari.paginate_array(@contents).page(params[:page]).per(8)
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
    @user = User.new(user_params)
    if !(set_admin.nil?) and can? :manage, User
      @user.is_admin = set_admin
    end
    auth!
    
    if @user.save
      flash[:notice] = t(:user_created)
    end
    #once an admin creates a user, don't go to the users page, go back to the user manage page
    respond_with(@user) do |format|
      format.html { redirect_to main_app.users_path }
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
    if @user.update_attributes(user_params)
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

    unless @user.screens.empty?
      redirect_to(@user, :notice => t(:user_owns_screens))
      return
    end
    
    #deleting the last admin is still forbidden in the model, but it's nice to catch it here too
    if @user.is_last_admin?
      redirect_to(@user, :notice => t(:cannot_delete_last_admin))
      return    
    end

    @user.destroy
    respond_with(@user)
  end

private

  # Restrict the allowed parameters to a select set defined in the model.
  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :receive_moderation_notifications, :locale, :time_zone)
  end
  
end

class UsersController < ApplicationController
  load_and_authorize_resource :except => [:index]
  respond_to :html, :json
   
  # GET /users
  def index
    authorize! :list, User
    respond_with(@users = User.all)
  end

  # GET /users/1
  def show
    respond_with(@user = User.find(params[:id]))
  end

  # GET /users/new
  def new
    @user = User.new
    respond_with(@user)
  end

  # POST /users
  def create
    @user = User.new(params[:user])
    respond_with(@user, :location => users_url)
  end
  
  # GET /users/1/edit
  def edit
    respond_with(@user = User.find(params[:id]))  
  end
  
  # PUT /users/1
  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:notice] = t(:user_updated)
    end
    respond_with(@user)
  end

  # DELETE /users/1
  def destroy
    @user = User.find(params[:id])
    @user.destroy
    respond_with(@user)
  end
  
end

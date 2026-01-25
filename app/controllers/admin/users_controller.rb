module Admin
  class UsersController < ApplicationController
    before_action :authenticate_user!
    before_action :set_user, only: %i[edit update destroy]
    after_action :verify_authorized

    # GET /admin/users/new
    def new
      @user = User.new
      authorize @user, :admin_create?
    end

    # POST /admin/users
    def create
      @user = User.new(user_params)
      authorize @user, :admin_create?

      if @user.save
        redirect_to user_url(@user), notice: "User was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin/users/:id/edit
    def edit
      authorize @user, :admin_manage?
    end

    # PATCH/PUT /admin/users/:id
    def update
      authorize @user, :admin_manage?

      result = if password_provided?
        @user.update(user_params)
      else
        @user.update_without_password(user_params.except(:password, :password_confirmation))
      end

      if result
        redirect_to user_url(@user), notice: "User was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin/users/:id
    def destroy
      authorize @user, :admin_manage?

      if last_system_admin?(@user)
        redirect_to user_url(@user), alert: "Cannot delete the last system administrator."
        return
      end

      @user.destroy!
      redirect_to users_url, notice: "User was successfully deleted."
    end

    private

    def set_user
      @user = User.find(params.expect(:id))
    end

    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
    end

    def password_provided?
      params.dig(:user, :password).present?
    end

    def last_system_admin?(user)
      return false unless user.system_admin?
      Group.system_admins_group&.users&.count <= 1
    end
  end
end

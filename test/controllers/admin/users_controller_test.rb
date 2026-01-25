require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    @system_admin = users(:system_admin)
    sign_in @system_admin
  end

  teardown do
    sign_out :user
  end

  # --- Authorization Tests ---

  test "should require authentication for all actions" do
    sign_out :user

    get new_admin_user_url
    assert_redirected_to new_user_session_url

    post admin_users_url, params: { user: { first_name: "Test", last_name: "User", email: "test@example.com", password: "password123", password_confirmation: "password123" } }
    assert_redirected_to new_user_session_url

    get edit_admin_user_url(@user)
    assert_redirected_to new_user_session_url

    patch admin_user_url(@user), params: { user: { first_name: "Updated" } }
    assert_redirected_to new_user_session_url

    delete admin_user_url(@user)
    assert_redirected_to new_user_session_url
  end

  test "should not allow regular users to access admin user actions" do
    sign_in users(:regular)

    get new_admin_user_url
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should not allow non-member users to access admin user actions" do
    sign_in users(:non_member)

    get new_admin_user_url
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should allow system admin to access admin user actions" do
    get new_admin_user_url
    assert_response :success
  end

  # --- CRUD Functionality Tests ---

  test "should get new" do
    get new_admin_user_url
    assert_response :success
    assert_select "h2", text: "Create User"
  end

  test "should create user" do
    assert_difference("User.count") do
      post admin_users_url, params: {
        user: {
          first_name: "New",
          last_name: "User",
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    new_user = User.find_by(email: "newuser@example.com")
    assert_redirected_to user_url(new_user)
    assert_equal "User was successfully created.", flash[:notice]
  end

  test "should not create user with invalid params" do
    assert_no_difference("User.count") do
      post admin_users_url, params: {
        user: {
          first_name: "",
          last_name: "",
          email: "invalid",
          password: "short",
          password_confirmation: "mismatch"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create user without password" do
    assert_no_difference("User.count") do
      post admin_users_url, params: {
        user: {
          first_name: "New",
          last_name: "User",
          email: "newuser@example.com",
          password: "",
          password_confirmation: ""
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_admin_user_url(@user)
    assert_response :success
    assert_select "h2", text: "Edit User"
  end

  test "should update user without changing password" do
    patch admin_user_url(@user), params: {
      user: {
        first_name: "Updated",
        last_name: "Name",
        email: @user.email,
        password: "",
        password_confirmation: ""
      }
    }

    assert_redirected_to user_url(@user)
    assert_equal "User was successfully updated.", flash[:notice]

    @user.reload
    assert_equal "Updated", @user.first_name
    assert_equal "Name", @user.last_name
  end

  test "should update user with new password" do
    patch admin_user_url(@user), params: {
      user: {
        first_name: @user.first_name,
        last_name: @user.last_name,
        email: @user.email,
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
    }

    assert_redirected_to user_url(@user)
    assert_equal "User was successfully updated.", flash[:notice]

    # Verify the password was actually changed
    @user.reload
    assert @user.valid_password?("newpassword123")
  end

  test "should not update user with mismatched passwords" do
    patch admin_user_url(@user), params: {
      user: {
        first_name: @user.first_name,
        last_name: @user.last_name,
        email: @user.email,
        password: "newpassword123",
        password_confirmation: "different123"
      }
    }

    assert_response :unprocessable_entity
  end

  test "should destroy user" do
    assert_difference("User.count", -1) do
      delete admin_user_url(@user)
    end

    assert_redirected_to users_url
    assert_equal "User was successfully deleted.", flash[:notice]
  end

  # --- Admin Self-Management Protection ---

  test "should not allow admin to edit themselves" do
    get edit_admin_user_url(@system_admin)
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should not allow admin to update themselves" do
    patch admin_user_url(@system_admin), params: { user: { first_name: "Updated" } }
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should not allow admin to destroy themselves" do
    assert_no_difference("User.count") do
      delete admin_user_url(@system_admin)
    end

    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should not allow admin to manage system users" do
    system_user = users(:system_user)

    get edit_admin_user_url(system_user)
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  # --- Last System Admin Protection ---

  test "should not destroy last system admin" do
    # Add another admin who will try to delete the only system admin
    other_admin = users(:admin)
    system_admins_group = Group.system_admins_group
    Membership.create!(user: other_admin, group: system_admins_group, role: :admin)

    # Now sign in as other_admin and try to delete system_admin
    sign_in other_admin

    # Remove other_admin from system admins group so system_admin is the last one
    membership = other_admin.memberships.find_by(group: system_admins_group)
    membership.delete
    assert_equal 1, Group.system_admins_group.users.count

    # other_admin is no longer a system admin, so they can't delete anyone
    assert_no_difference("User.count") do
      delete admin_user_url(@system_admin)
    end

    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should allow admin to destroy another system admin if there are multiple" do
    # Add another user to the system admins group
    other_admin = users(:admin)
    system_admins_group = Group.system_admins_group
    Membership.create!(user: other_admin, group: system_admins_group, role: :admin)

    assert_operator Group.system_admins_group.users.count, :>, 1

    # system_admin (signed in) deletes other_admin
    assert_difference("User.count", -1) do
      delete admin_user_url(other_admin)
    end

    assert_redirected_to users_url
    assert_equal "User was successfully deleted.", flash[:notice]
  end

  # --- UI Integration Tests ---

  test "system admin should see new user button on users index" do
    get users_url
    assert_response :success
    assert_select "a[href='#{new_admin_user_path}']", text: /New User/
  end

  test "regular user should not see new user button on users index" do
    sign_in users(:regular)
    get users_url
    assert_response :success
    assert_select "a[href='#{new_admin_user_path}']", count: 0
  end

  test "system admin should see edit and delete buttons on user show page" do
    get user_url(@user)
    assert_response :success
    assert_select "a[href='#{edit_admin_user_path(@user)}']", text: /Edit User/
    assert_select "form[action='#{admin_user_path(@user)}'] button", text: /Delete User/
  end

  test "system admin should not see edit and delete buttons on their own profile" do
    get user_url(@system_admin)
    assert_response :success
    assert_select "a[href='#{edit_admin_user_path(@system_admin)}']", count: 0
    assert_select "form[action='#{admin_user_path(@system_admin)}'] button", count: 0
  end

  test "system admin should not see edit and delete buttons for system user" do
    system_user = users(:system_user)
    get user_url(system_user)
    assert_response :success
    assert_select "a[href='#{edit_admin_user_path(system_user)}']", count: 0
    assert_select "form[action='#{admin_user_path(system_user)}'] button", count: 0
  end

  test "regular user should not see edit and delete buttons on user show page" do
    sign_in users(:regular)
    other_user = users(:non_member)
    get user_url(other_user)
    assert_response :success
    assert_select "a[href='#{edit_admin_user_path(other_user)}']", count: 0
    assert_select "form[action='#{admin_user_path(other_user)}'] button", count: 0
  end
end

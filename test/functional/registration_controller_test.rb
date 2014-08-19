require 'test_helper'

class ConcertoDeviseRegistrationsControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  tests ConcertoDevise::RegistrationsController

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  def unsetup_everything
    User.all.each do |u|
      u.screens.each { |s| s.destroy }
    end
    User.all.each do |u|
      u.destroy
    end
    ConcertoConfig.set("setup_complete", "false")
  end

  test "should get registration" do
    get :new
    assert_response :success
  end

  test "registration form diabled" do
    ConcertoConfig.set("allow_registration", "false")
    get :new
    assert_response :redirect
  end

  test "registration processing disabled" do
    ConcertoConfig.set("allow_registration", "false")
    post :create, {:user => {:first_name => "Name", :last_name => "Last", :email => "a@a.com"}}
    assert_response :redirect
  end

  test "user can change password" do
    sign_in users(:karen)
    put :update, {:user => { :current_password => 'password', :password => 'pass1234', :password_confirmation => 'pass1234' } }

    assert User.find(users(:karen).id).valid_password?('pass1234')
  end

  test "new admin registration" do
    unsetup_everything

    get :new
    assert_response :success
    assert_select '#concerto_config_send_errors[checked]'
  end

  test "new admin send errors" do
    unsetup_everything

    assert_difference('User.count', 1) do
      post :create, {:user => {:first_name => "Name", :last_name => "Last", :email => "a@a.com", :password => 'pass1234', :password_confirmation => 'pass1234'}, :concerto_config => {:send_errors => "true"}}
    end
    assert_equal true, ConcertoConfig[:send_errors]
    assert_equal 1, User.admin.count
  end

  test "new admin no errors" do
    unsetup_everything

    assert_difference('User.count', 1) do
      post :create, {:user => {:first_name => "Name", :last_name => "Last", :email => "a@a.com", :password => 'pass1234', :password_confirmation => 'pass1234'}, :concerto_config => {:send_errors => "false"}}
    end
    assert_equal false, ConcertoConfig[:send_errors]
  end
end

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

  test "registration form disabled" do
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
  end

  test "new admin" do
    unsetup_everything

    assert_difference('User.count', 1) do
      post :create, {:user => {:first_name => "Name", :last_name => "Last", :email => "a@a.com", :password => 'pass1234', :password_confirmation => 'pass1234'}}
    end
  end
end

require 'test_helper'

class ConcertoDeviseRegistrationsControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  tests ConcertoDevise::RegistrationsController

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
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
end

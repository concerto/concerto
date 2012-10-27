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
end

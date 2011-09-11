require 'test_helper'

class DeviseRegistrationsControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  tests Devise::RegistrationsController

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "should get registration" do
    get :new
    assert_response :success
  end

end

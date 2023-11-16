require 'test_helper'

class ConcertoPluginsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "not signed in user cannot access" do
    get :index, params: {}
    assert_login_failure
  end

  test "regular signed in user cannot access" do
    sign_in users(:katie)
    get :index, params: {}
    assert_login_failure
  end

  test "admin user sees empty page" do
    sign_in users(:admin)
    get :index, params: {}
    assert_response :success
    assert_not_nil assigns(:concerto_plugins)
  end
end



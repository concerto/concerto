require 'test_helper'

class DashboardControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "must sign in before dashboard" do
    get :show, params: {}
    assert_redirected_to feeds_path
  end

  test "dashboard loads for owner" do
    sign_in users(:katie)
    get :show, params: {}
    assert_response :success
  end

  test "dashboard loads for regular" do
    sign_in users(:kristen)
    get :show, params: {}
    assert_response :success
  end
end

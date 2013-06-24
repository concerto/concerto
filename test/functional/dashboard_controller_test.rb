require 'test_helper'

class DashboardControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "must sign in before dashboard" do
    get :show
    assert_redirected_to feeds_path
  end

  test "dashboard loads for owner" do
    sign_in users(:katie)
    get :show
    assert_response :success
  end

  test "dashboard loads for regular" do
    sign_in users(:kristen)
    get :show
    assert_response :success
  end
end

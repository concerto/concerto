require 'test_helper'

class ConcertoConfigControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "must be admin to show" do
    get :show
    assert_login_failure

    sign_in users(:katie)
    get :show
    assert_login_failure
  end

  test "admin can show" do
    sign_in users(:admin)
    get :show
    assert_response :success
  end

  test "configs can be updated" do
    sign_in users(:admin)
    put :update, :concerto_config => {"public_concerto"=>"false", "new_key"=>"new_value"}
    assert_redirected_to concerto_config_path
    assert !ConcertoConfig[:public_concerto]
    assert_equal "new_value", ConcertoConfig[:new_key]
  end

  test "regular cannot update" do
    put :update, :concerto_config => {"public_concerto"=>"false"}
    assert_login_failure
    assert ConcertoConfig[:public_concerto]

    sign_in users(:katie)
    assert_login_failure
    assert ConcertoConfig[:public_concerto]
  end

end

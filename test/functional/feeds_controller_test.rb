require 'test_helper'

class FeedsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "must sign in before new" do
    get :new, params: {}
    assert_login_failure
  end

  test "not signed in user has nothing to moderate" do
    get :index, params: {}
    assert assigns(:pending_submissions_count)
    assert_equal 0, assigns(:pending_submissions_count)
  end

  test "moderator has pending submissions" do
    sign_in users(:katie)
    get :index, params: {}
    assert assigns(:pending_submissions_count)
    assert_equal 3, assigns(:pending_submissions_count)
  end

  test "moderate index shows pending submissions" do
    sign_in users(:katie)
    get :moderate, params: {}
    assert assigns(:feeds)
    assert assigns(:feeds).include?(feeds(:service))
  end

  test "moderate page not allowed without sign in" do
    get :moderate, params: {}
    assert_login_failure
  end

  test "signed in top bar critical links" do
    sign_in users(:katie)
    get :index, params: {}

    key_text = ['Browse', 'Screens', 'User Groups']
    key_text.each do |text|
      assert_select 'nav>section>div>a', text
    end

    key_links = [feeds_path, screens_path, groups_path]
    key_links.each do |link|
      assert_select 'nav>section>div>a[href=?]', link
    end
  end

end

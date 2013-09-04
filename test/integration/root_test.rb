require 'test_helper'

class RootTest < ActionController::IntegrationTest
  fixtures :all

  test "root url loads" do
    get "/"

    # The page always loads
    assert_response :success

    # And it should never ever ever redirect
    assert !redirect?
  end

  test "signed in root urls load" do
    post "/users/sign_in", :user => {:email => users(:katie).email, :password => 'katie'}
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_response :success

    get "/feeds"
    assert_response :success

    get "/feeds/#{feeds(:service).id}/submissions"
    assert_response :success
  end
end

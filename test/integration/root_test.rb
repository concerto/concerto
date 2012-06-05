require 'test_helper'

class RootTest < ActionController::IntegrationTest
  fixtures :all

  test "root url loads" do
    get "/"

    # The page always loads
    assert :success

    # And it should never ever ever redirect
    assert !redirect?
  end

  test "signed in root urls load" do
    post "/users/sign_in", :user => {:email => users(:katie).email, :password => 'katie'}
    assert :success

    get "/feeds"
    assert :success

    get "/feeds/#{feeds(:service).id}/submissions"
    assert :success
  end
end

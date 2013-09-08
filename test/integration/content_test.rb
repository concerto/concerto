require 'test_helper'

class ContentTest < ActionController::IntegrationTest
  fixtures :all

  test "signed in root urls load" do
    post "/users/sign_in", :user => {:email => users(:katie).email, :password => 'katie'}
    assert :success

    get "/content/new?type=weather"
    assert :success
  end
end

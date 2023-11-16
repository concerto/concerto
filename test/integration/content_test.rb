require 'test_helper'

class ContentIntegrationTest < ActionDispatch::IntegrationTest
  fixtures :all

  test "signed in root urls load" do
    post "/users/sign_in", params: { :user => {:email => users(:katie).email, :password => 'katie'} }
    assert :success

    get "/content/new?type=weather"
    assert :success
  end

  test "missing content renders 404" do
    get "/content/abc123"
    assert :missing
  end
end

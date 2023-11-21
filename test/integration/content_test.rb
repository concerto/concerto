require 'test_helper'

class ContentIntegrationTest < ActionDispatch::IntegrationTest
  fixtures :all

  test "signed in root urls load" do
    post "/users/sign_in", params: { :user => {:email => users(:katie).email, :password => 'katie'} }
    assert :success

    get "/content/new?type=weather", params: {}
    assert :success
  end

  test "missing content renders 404" do
    get "/content/abc123", params: {}
    assert :missing
  end
end

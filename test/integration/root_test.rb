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
end

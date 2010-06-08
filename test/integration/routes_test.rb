require 'test_helper'

class RoutesTest < ActionController::IntegrationTest
  fixtures :all
  
  test "non plural content route" do
    # I believe we should be able to test the route like follows
    # in > Rails 3beta3.  Looks like the bug was closed a few weeks ago
    # https://rails.lighthouseapp.com/projects/8994/tickets/4390-patch-assert_recognizes-should-work-in-integration-tests
    # assert_recognizes contents_url, "content"
    
    #Until then, we'll use this guy
    assert_equal "/content", contents_path
  
  end  
end

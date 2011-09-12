require 'test_helper'

class RoutesTest < ActionController::IntegrationTest
  fixtures :all
  
  test "non plural content route" do
    assert_recognizes({:controller => 'contents', :action => 'index'}, "content")
    
    # A backup way to test this
    #assert_equal "/content", contents_path
  end  
end

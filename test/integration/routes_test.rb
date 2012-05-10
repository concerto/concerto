require 'test_helper'

class RoutesTest < ActionController::IntegrationTest
  fixtures :all
  
  test "non plural content route" do
    assert_recognizes({:controller => 'feeds', :action => 'index'}, "content")
    
    # A backup way to test this
    #assert_equal "/content", contents_path
  end  

  test "no screen path in frontend route" do
    assert_recognizes({:controller => 'frontend/screens', :action => 'show', :id => '1'}, "frontend/1")
  end
end

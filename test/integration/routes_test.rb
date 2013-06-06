require 'test_helper'

class RoutesTest < ActionController::IntegrationTest
  fixtures :all
  
  test "non plural content route" do
    assert_recognizes({:controller => 'feeds', :action => 'index'}, "content")
    
    # A backup way to test this
    assert_equal "/content", contents_path
  end  

  test "content upload does not mix with feeds" do
    assert_recognizes({:controller => 'contents', :action => 'create'}, {:path => 'content', :method => :post})
    assert_recognizes({:controller => 'feeds', :action => 'index'}, {:path => 'content', :method => :get})
  end

  test "no screen path in frontend route" do
    assert_recognizes({:controller => 'frontend/screens', :action => 'show', :id => '1'}, "frontend/1")
  end

  test "root url correct" do
    assert_recognizes({:controller => 'feeds', :action => 'index'}, '/')
  end

  test "v1 screen urls work" do
    assert_recognizes({:controller => 'frontend/screens', :action => 'index'}, "?mac=123")
    assert_recognizes({:controller => 'frontend/screens', :action => 'index'}, "screen?mac=123")
  end
end

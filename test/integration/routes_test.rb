require 'test_helper'

class RoutesTest < ActionDispatch::IntegrationTest
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

  test "screen urls OK" do
    assert_recognizes({:controller => 'screens', :action => 'index'}, 'screens')
    assert_recognizes({:controller => 'screens', :action => 'show', :id => '1'}, 'screens/1')
    assert_equal screen_path(screens(:one)), "/screens/#{screens(:one).id}"
  end
end

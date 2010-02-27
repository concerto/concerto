require 'test_helper'

class FeedTest < ActiveSupport::TestCase
  #Test the fields that should be required
  test "name cannot be blank" do
    f = feeds(:one)
    feed = Feed.new(f.attributes)
    feed.name = ""
    assert !feed.valid?, "Feed name is blank"
    feed.name = "Blah"
    assert feed.valid?, "Feed name has entry"
  end
  
  #Test for duplicate names
  test "name cannot be duplicated" do
    f = feeds(:one)
    feed = Feed.new({:name => f.name})
    assert_equal f.name, feed.name, "Names are set equal"
    assert !feed.valid?, "Names can't be equal"
    feed.name = "Fooasdasdasda"
    assert feed.valid?, "Unique name is OK"
  end
  
  #Test the content relationship
  # This test serves more to verify the setup of the 
  # testing enviroment than the actual application
  test "has content" do
    f = feeds(:one)
    assert_equal f.contents.length, 2, "Feed only has 2 contents"
    assert f.contents.include?(contents(:one)), "Content one is included"
    assert f.contents.include?(contents(:old)), "Content old is included"
  end
  
  #Test the approved/pending/denied content relationship
  test "approved content" do
    f = feeds(:one)
    assert_equal f.approved_contents, [contents(:one)], "Approved content is approved"
    
    no_approved = feeds(:two)
    assert no_approved.approved_contents.empty?, "Denied content is not approved"
  end
  test "pending content" do
    f = feeds(:one)
    assert_equal f.pending_contents, [contents(:old)], "Pending content is pending"
    
    no_pending = feeds(:two)
    assert no_pending.pending_contents.empty?, "Denied content is not pending"
  end
  test "denied content" do 
    f = feeds(:two)
    assert_equal f.denied_contents, [contents(:one)], "Denied content is denied"
    
    no_denied = feeds(:one)
    assert no_denied.denied_contents.empty?, "Pending|Approved is not denied"
  end
  
end

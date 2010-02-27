require 'test_helper'

class ContentTest < ActiveSupport::TestCase
  #Test the fields that should be required
  test "name cannot be blank" do
    c = contents(:one)
    content = Content.new(c.attributes)
    content.name = ""
    assert !content.valid?, "Content name is blank"
    content.name = "Blah"
    assert content.valid?, "Content name has entry"
  end
  test "mime type cannot be blank" do
    c = contents(:one)
    content = Content.new(c.attributes)
    content.mime_type = ""
    assert !content.valid?, "Content mime_type is blank"
    content.mime_type = "Blah"
    assert content.valid?, "Content mime_type has entry"
  end
  test "type cannot be blank or unassociated" do
    c = contents(:one)
    content = Content.new(c.attributes)
    content.type_id = ""
    assert !content.valid?, "Content type is blank"
    content.type_id = 0
    assert !content.valid?, "Content type is unassociated"
    content.type_id = types(:text).id
    assert content.valid?, "Content type is associated with text"
  end

  #Testing the is_active? method, mixing dates and nils
  test "is active for nulls" do 
    c = contents(:one)
    c.start_time = nil
    c.end_time = nil
    assert c.is_active?, "Two nils are active"
  end
  test "is active date/null" do 
    c = contents(:one)
    c.start_time = 1.day.ago
    c.end_time = nil
    assert c.is_active?, "Old date / Nil are active"
    
    c.start_time = 1.day.from_now
    assert !c.is_active?, "Future date / Nil not active"
  end
  test "is active null/date" do 
    c = contents(:one)
    c.start_time = nil
    c.end_time = 1.day.ago
    assert !c.is_active?, "Nil / old date not active"
    
    c.end_time = 1.day.from_now
    assert c.is_active?, "Nil / future date active"
  end
  test "is active date/date" do 
    c = contents(:one)
    c.start_time = 1.day.from_now
    c.end_time = 1.day.ago
    assert !c.is_active?, "Future date / past date not active"
    
    c.end_time = 1.day.from_now
    assert !c.is_active?, "Future date / future date not active"
    
    c.start_time = 1.day.ago
    assert c.is_active?, "Old date / future date active"
  end
  
  #Test the scoping for past/present/future content
  test "active content" do 
    active = Content.active.all
    assert contents(:one).is_active?, "Content is active"
    assert_equal active.length, 1, "Only 1 active content"
    assert_equal active.first, contents(:one), "Active content found"
  end
  test "expired content" do 
    expired = Content.expired.all
    assert_operator contents(:old).end_time, :<, Time.now, "Content is expired"
    assert_equal expired.length, 1, "Only 1 expired content"
    assert_equal expired.first, contents(:old), "Expired content found"
  end
    test "future content" do 
    future = Content.future.all
    assert_operator contents(:new).start_time, :>, Time.now, "Content is future"
    assert_equal future.length, 1, "Only 1 future content"
    assert_equal future.first, contents(:new), "Future content found"
  end

  
end

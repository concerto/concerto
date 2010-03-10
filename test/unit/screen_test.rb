require 'test_helper'

class ScreenTest < ActiveSupport::TestCase
  #Test the fields that should be required
  test "name cannot be blank" do
    s = screens(:one)
    screen = Screen.new(s.attributes)
    screen.owner = users(:katie)
    screen.name = ""
    assert !screen.valid?, "Screen name is blank"
    screen.name = "Blah"
    assert screen.valid?, "Screen name has entry"
  end
  test "template cannot be blank or unassociated" do
    s = screens(:one)
    screen = Screen.new(s.attributes)
    screen.template_id = ""
    assert !screen.valid?, "Screen template is blank"
    screen.template_id = 0
    assert !screen.valid?, "Screen template is unassociated"
    screen.template_id = templates(:one).id
    assert screen.valid?, "Screen template is associated with one"
  end  
  test "owner must be group or user" do
    s = screens(:one)
    s.owner = users(:katie)
    assert s.valid?, "Screen owned by user"
    s.owner_type = "Pants"
    assert !s.valid?, "Screen cannot be owner by pants"
    s.owner_type = "User"
    assert s.valid?, "Screen can be owner by user"
    s.owner = groups(:wtg)
    assert s.valid?, "Screen can be owner by group"
    s.owner = nil
    s.owner_type = "Group"
    s.owner_id = ""
    assert !s.valid?, "Screen owner must be set"
    s.owner = nil
    s.owner_type = ""
    s.owner_id = users(:kristen).id
    assert !s.valid?, "Screen owner type must be set"
    s.owner = nil
    s.owner_type = "User"
    s.owner_id = 0
    assert !s.valid?, "Screen owner must be valid"
  end
end

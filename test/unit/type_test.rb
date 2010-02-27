require 'test_helper'

class TypeTest < ActiveSupport::TestCase
  #Test the fields that should be required
  test "name cannot be blank" do
    t = types(:text)
    type = Type.new(t.attributes)
    type.name = ""
    assert !type.valid?, "Type name is blank"
    type.name = "Blah"
    assert type.valid?, "Type name has entry"
  end
  
  #Test for duplicate names
  test "name cannot be duplicated" do
    t = types(:text)
    type = Type.new({:name => t.name})
    assert_equal t.name, type.name, "Names are set equal"
    assert !type.valid?, "Names can't be equal"
    type.name = "Fooasdasdasda"
    assert type.valid?, "Unique name is OK"
  end
end

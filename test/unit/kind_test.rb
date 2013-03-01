require 'test_helper'

class KindTest < ActiveSupport::TestCase
  #Test the fields that should be required
  test "name cannot be blank" do
    k = kinds(:text)
    kind = Kind.new(k.attributes)
    kind.name = ""
    assert !kind.valid?, "Kind name is blank"
    kind.name = "Blah"
    assert kind.valid?, "Kind name has entry"
  end
  
  #Test for duplicate names
  test "name cannot be duplicated" do
    k = kinds(:text)
    kind = Kind.new({name: k.name})
    assert_equal k.name, kind.name, "Names are set equal"
    assert !kind.valid?, "Names can't be equal"
    kind.name = "Fooasdasdasda"
    assert kind.valid?, "Unique name is OK"
  end
end

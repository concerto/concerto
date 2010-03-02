require 'test_helper'

class GroupTest < ActiveSupport::TestCase
  #Test for duplicate names
  test "name cannot be duplicated" do
    g = groups(:wtg)
    group = Group.new({:name => g.name})
    assert_equal g.name, group.name, "Names are set equal"
    assert !group.valid?, "Names can't be equal"
    group.name = "Fooasdasdasda"
    assert group.valid?, "Unique name is OK"
  end
end

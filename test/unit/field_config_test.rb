require 'test_helper'

class FieldConfigTest < ActiveSupport::TestCase
  test "require things to be present" do
    fc = FieldConfig.new()
    fc.screen = screens(:one)
    assert !fc.valid?

    fc.field = fields(:one)
    assert !fc.valid?

    fc.key = "key"
    assert fc.valid?
  end

  test "no duplicate keys for a screen field" do
    fc = FieldConfig.new(:screen_id => screens(:one).id, :field_id => fields(:one).id, :key => "foo", :value => "bar")
    fc.save

    dup = FieldConfig.new(:screen_id => screens(:one).id, :field_id => fields(:one).id, :key => "foo", :value => "baz")
    assert !dup.valid?

    dup.screen = screens(:two)
    assert dup.valid?
  end
end

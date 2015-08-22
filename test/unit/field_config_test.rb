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

  test "fieldconfig get" do
    assert FieldConfig.get(screens(:one), fields(:one), 'missing').nil?
    assert_equal 'valuehere', FieldConfig.get(screens(:one), fields(:one), 'keyname')
  end

  test "owning group or user can manage" do
    fc = field_configs(:one)
    ability = Ability.new(users(:katie))
    assert ability.can?(:manage, field_configs(:one))  # owner
    assert ability.can?(:manage, field_configs(:three))  # group leader

    ability = Ability.new(users(:kristen))
    assert ability.cannot?(:manage, field_configs(:one))
  end

  test "identify type of key" do
    fc = field_configs(:one)
    assert fc.key_type.nil?

    fc = field_configs(:three)
    assert_equal :select, fc.key_type

    fc = field_configs(:four)
    assert_equal :select, fc.key_type
  end

  test ":select key has options" do
    fc = field_configs(:one)
    assert fc.key_options.blank?

    fc = field_configs(:three)
    assert !fc.key_options.blank?

    fc = field_configs(:four)
    assert !fc.key_options.blank?
  end
end

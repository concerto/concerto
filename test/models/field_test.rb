require "test_helper"

class FieldTest < ActiveSupport::TestCase
  test "default fields exist" do
    assert Field.exists?(name: "Main")
    assert Field.exists?(name: "Sidebar")
    assert Field.exists?(name: "Ticker")
    assert Field.exists?(name: "Time")
  end

  test "common field names exist" do
    [ "Graphics", "Text" ].each do |name|
      found = false
      Field.all.each do |field|
        if field.alt_names.include? "Text"
          found = true
        end
      end
      assert found, "#{name} field not found"
    end
  end

  test "name is required" do
    field = Field.new(name: "")
    assert_not field.valid?
    assert_includes field.errors[:name], "can't be blank"
  end

  test "name must be unique case-insensitively" do
    field = Field.new(name: "main")
    assert_not field.valid?
    assert_includes field.errors[:name], "has already been taken"
  end

  test "in_use? is true when referenced by a position" do
    assert fields(:main).in_use?
  end

  test "in_use? is false for a brand new field" do
    assert_not Field.create!(name: "Lonely").in_use?
  end

  test "cannot be destroyed while referenced" do
    field = fields(:main)
    assert_not field.destroy
    assert Field.exists?(field.id)
  end
end

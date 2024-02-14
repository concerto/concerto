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
end

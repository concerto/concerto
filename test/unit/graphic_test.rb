require 'test_helper'

class GraphicTest < ActiveSupport::TestCase
  # Attributes cannot be left empty/blank
  test "graphic attributes must not be empty" do
    graphic = Graphic.new
    assert graphic.invalid?
    assert graphic.errors[:duration].any?
    assert graphic.errors[:media].any?
  end
  
  #Verify the kind is getting auto-assigned
  test "kind should be auto set" do
    graphic = Graphic.new
    assert_equal graphic.kind, Kind.where(:name => "Graphics").first
  end
end

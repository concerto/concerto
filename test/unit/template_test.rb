require 'test_helper'
include ActionDispatch::TestProcess

class TemplateTest < ActiveSupport::TestCase
  # Test the ability to import a simple xml descriptor
  test "importing a simple template" do
    t = Template.new
    file = fixture_file_upload("/files/simple_template.xml", 'text/xml')
    assert t.import_xml(file.read)
    actual = t.positions.first
    assert_equal 0.025, actual.left
    assert_equal 0.026, actual.top
    assert_equal 0.592, actual.right
    assert_equal 0.796, actual.bottom
  end

  test "importing a template with multiple positions" do
    t = Template.new
    file = fixture_file_upload("/files/two_field_template.xml", 'text/xml')
    assert t.import_xml(file.read)
    actual = t.positions
    # first position
    assert_equal 0.025, actual.first.left
    assert_equal 0.026, actual.first.top
    assert_equal 0.592, actual.first.right
    assert_equal 0.796, actual.first.bottom
    # second position
    assert_equal 0.025, actual.last.left
    assert_equal 0.796, actual.last.top
    assert_equal 0.592, actual.last.right
    assert_equal 1.000, actual.last.bottom
    
  end
  
  # Test the ability to import a template without fields
  test "importing an empty template" do
    t = Template.new
    file = fixture_file_upload("/files/no_fields_template.xml", 'text/xml')
    assert t.import_xml(file.read)
  end

  # Do we correctly find the original height and orignal width?
  test "find original height and width" do
    t = Template.new
    file = fixture_file_upload("/files/concerto_background.jpg", 'image/jpeg')
    t.save
    media = t.media.build(:file => file, :key => 'original')
    media.save
    assert t.update_original_sizes
    assert_equal t.original_width, 1920
    assert_equal t.original_height, 1200
  end
end

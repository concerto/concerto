require 'test_helper'
include ActionDispatch::TestProcess

class TemplateTest < ActiveSupport::TestCase
  # Test the ability to import a simple xml descriptor
  test "importing a simple template" do
    t = Template.new
    file = fixture_file_upload("/files/simple_template.xml", 'text/xml')
    assert t.import_xml(file.read)
    assert_equal t.positions.size, 1
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

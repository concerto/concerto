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
end

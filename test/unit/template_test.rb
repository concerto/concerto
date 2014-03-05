require 'test_helper'
include ActionDispatch::TestProcess

class TemplateTest < ActiveSupport::TestCase

  fixtures :all

  # Test the ability to import a simple xml descriptor
  test "importing a simple template" do
    t = Template.new
    file = fixture_file_upload("/files/simple_template.xml", 'text/xml')
    assert t.import_xml(file.read)
    actual = t.positions.first
    assert_small_delta 0.025, actual.left
    assert_small_delta 0.026, actual.top
    assert_small_delta 0.592, actual.right
    assert_small_delta 0.796, actual.bottom
    assert_equal false, t.is_hidden
  end

  test "importing a template with multiple positions" do
    t = Template.new
    file = fixture_file_upload("/files/two_field_template.xml", 'text/xml')
    assert t.import_xml(file.read)
    actual = t.positions
    # first position
    assert_small_delta 0.025, actual.first.left
    assert_small_delta 0.026, actual.first.top
    assert_small_delta 0.592, actual.first.right
    assert_small_delta 0.796, actual.first.bottom
    # second position
    assert_small_delta 0.025, actual.last.left
    assert_small_delta 0.796, actual.last.top
    assert_small_delta 0.592, actual.last.right
    assert_small_delta 1.000, actual.last.bottom
    
  end
  
  # Test the ability to import a template without fields
  test "importing an empty template" do
    t = Template.new
    file = fixture_file_upload("/files/no_fields_template.xml", 'text/xml')
    assert t.import_xml(file.read)
  end

  test "importing a bogus archive" do
    t = Template.new
    assert !t.import_archive(nil)
    tf = ActionDispatch::Http::UploadedFile.new({:tempfile => 'bogus', :filename => 'bogus.txt', :head => nil, :type => 'txt'})
    assert !t.import_archive(tf)
  end

  # Do we correctly find the original height and orignal width?
  test "find original height and width" do
    t = Template.new
    file = fixture_file_upload("/files/concerto_background.jpg", 'image/jpeg')
    t.save
    media = t.media.build(:file => file, :key => 'original')
    media.save
    assert t.update_original_sizes
    assert_equal 1920, t.original_width
    assert_equal 1200, t.original_height
  end

  test "template names must be unique" do
    t = templates(:one)
    templ = Template.new({:name => t.name})
    assert_equal t.name, templ.name, "Names are set equal"
    assert !templ.valid?, "Names can't be equal"
    templ.name = "Fooasdasdasda"
    assert templ.valid?, "Unique name is OK"
  end

  test "can't delete template if in use" do
    t = templates(:one)
    assert !t.is_deletable?
  end

  test "get screens that use this template" do
    t = templates(:one)
    t.screen_dependencies.include?(screens(:one))
  end
end

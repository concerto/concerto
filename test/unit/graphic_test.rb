require 'test_helper'
include ActionDispatch::TestProcess

class GraphicTest < ActiveSupport::TestCase
  # Attributes cannot be left empty/blank
  test "graphic attributes must not be empty" do
    graphic = Graphic.new
    assert graphic.invalid?
    assert graphic.errors[:duration].any?
    assert graphic.errors[:media].any?
  end
  
  # Verify the kind is getting auto-assigned
  test "kind should be auto set" do
    graphic = Graphic.new
    assert_equal Kind.where(:name => "Graphics").first, graphic.kind
  end

  # Graphics require imagess to be attached
  # Note: This isn't an accurate simulation of the
  # actual file upload process.  We should run that in
  # the integration test
  test "graphics require a file" do
    graphic = Graphic.new(:name => "Sample Graphic",
                          :duration => 15,
                          :user => users(:katie))
    file = fixture_file_upload("/files/concerto_background.jpg", 'image/jpeg', :binary)
    graphic.media.build({:key => "original"})
    graphic.media.first.file = file

    assert graphic.valid?
    assert graphic.save
  end

  # Only a subset of files are valid graphics.
  test "graphics must be images" do
    graphic = Graphic.new(:name => "Sample Graphic",
                      :duration => 15,
                      :user => users(:katie))
    file = fixture_file_upload("/files/concerto_background.jpg", 'text/plain', :binary)
    graphic.media.build({:key => "original"})
    graphic.media.first.file = file

    assert graphic.invalid?
    assert graphic.errors[:media].any?
  end

  test "graphic class has display name" do
    assert_equal "Graphic", Graphic.display_name
  end

  test "preview is reflexive" do
    assert_equal "ABC", Graphic::preview("ABC")
  end

  test "form attributes include media attributes" do
    Graphic.form_attributes.include?(:media_attributes)
  end

  test "render_details includes path" do
    graphic = Graphic.new(:name => "Sample Graphic",
                          :duration => 15,
                          :user => users(:katie))
    file = fixture_file_upload("/files/concerto_background.jpg", 'image/jpeg', :binary)
    graphic.media.build({:key => "original"})
    graphic.media.first.file = file
    graphic.save
    graphic.pre_render(screens(:one), fields(:one))
    assert graphic.render_details.include?(:path)
  end
end

require "test_helper"

class TemplateTest < ActiveSupport::TestCase
  test "aspect_ratio is inferred from the analyzed background image" do
    # two_template_blob is fixtured as a 1920x1080 (16:9) image.
    assert_equal 1920.0 / 1080, templates(:two).aspect_ratio
  end

  test "aspect_ratio falls back to 16:9 when no image is attached" do
    assert_not templates(:one).image.attached?
    assert_equal Template::DEFAULT_ASPECT_RATIO, templates(:one).aspect_ratio
  end

  test "aspect_ratio falls back to 16:9 when the image is not yet analyzed" do
    template = Template.new(name: "Test", author: "Test")
    template.image.attach(io: file_fixture("template_portrait.png").open, filename: "template_portrait.png", content_type: "image/png")
    template.save!

    assert_not template.image.analyzed?
    assert_equal Template::DEFAULT_ASPECT_RATIO, template.aspect_ratio
  end
end

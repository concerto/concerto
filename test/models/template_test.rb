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

  test "in_use? is true when referenced by a screen" do
    assert templates(:two).in_use?
  end

  test "in_use? is false when not referenced by any screen" do
    assert_not templates(:unused).in_use?
  end

  test "cannot be destroyed while referenced by a screen" do
    template = templates(:two)
    position_ids = template.positions.pluck(:id)
    assert position_ids.any?

    assert_not template.destroy
    assert Template.exists?(template.id)
    assert_equal position_ids.sort, template.positions.reload.pluck(:id).sort
    assert_includes template.errors[:base], "Cannot delete record because dependent screens exist"
  end

  test "can be destroyed when not referenced by any screen" do
    template = templates(:unused)

    assert template.destroy
    assert_not Template.exists?(template.id)
  end
end

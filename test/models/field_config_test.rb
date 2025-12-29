require "test_helper"

class FieldConfigTest < ActiveSupport::TestCase
  setup do
    @screen = screens(:two)  # Use screen two to avoid fixture conflicts
    @field = fields(:ticker)  # Use ticker field which doesn't have configs in fixtures
    @content = rich_texts(:plain_richtext)
  end

  test "valid field config" do
    field_config = FieldConfig.new(
      screen: @screen,
      field: @field,
      pinned_content: @content
    )
    assert field_config.valid?
  end

  test "valid field config without pinned content" do
    field_config = FieldConfig.new(
      screen: @screen,
      field: @field,
      pinned_content: nil
    )
    assert field_config.valid?
  end

  test "requires screen" do
    field_config = FieldConfig.new(
      field: @field,
      pinned_content: @content
    )
    assert_not field_config.valid?
    assert_includes field_config.errors[:screen], "must exist"
  end

  test "requires field" do
    field_config = FieldConfig.new(
      screen: @screen,
      pinned_content: @content
    )
    assert_not field_config.valid?
    assert_includes field_config.errors[:field], "must exist"
  end

  test "enforces uniqueness of screen and field combination" do
    # First config
    FieldConfig.create!(
      screen: @screen,
      field: @field,
      pinned_content: @content
    )

    # Duplicate config
    duplicate_config = FieldConfig.new(
      screen: @screen,
      field: @field,
      pinned_content: nil
    )

    assert_not duplicate_config.valid?
    assert_includes duplicate_config.errors[:screen_id], "already has a config for this field"
  end

  test "allows multiple configs for same screen with different fields" do
    config1 = FieldConfig.create!(
      screen: @screen,
      field: fields(:ticker),
      pinned_content: @content
    )

    config2 = FieldConfig.create!(
      screen: @screen,
      field: fields(:time),
      pinned_content: nil
    )

    assert config1.valid?
    assert config2.valid?
  end

  test "allows multiple configs for same field with different screens" do
    config1 = FieldConfig.create!(
      screen: screens(:one),
      field: @field,
      pinned_content: @content
    )

    config2 = FieldConfig.create!(
      screen: screens(:two),
      field: @field,
      pinned_content: nil
    )

    assert config1.valid?
    assert config2.valid?
  end

  test "belongs to screen" do
    field_config = field_configs(:with_pinned_content)
    assert_equal screens(:one), field_config.screen
  end

  test "belongs to field" do
    field_config = field_configs(:with_pinned_content)
    assert_equal fields(:main), field_config.field
  end

  test "belongs to pinned content" do
    field_config = field_configs(:with_pinned_content)
    assert_instance_of RichText, field_config.pinned_content
  end

  test "pinned content can be nil" do
    field_config = field_configs(:without_pinned_content)
    assert_nil field_config.pinned_content
  end

  test "destroying screen destroys field configs" do
    screen = screens(:one)
    assert_difference "FieldConfig.count", -2 do
      screen.destroy
    end
  end

  test "destroying content nullifies pinned_content_id" do
    field_config = field_configs(:with_pinned_content)
    content = field_config.pinned_content

    assert_no_difference "FieldConfig.count" do
      content.destroy
    end

    field_config.reload
    assert_nil field_config.pinned_content_id
  end

  test "validates field belongs to screen's template" do
    # Create a field that doesn't belong to the template
    other_field = Field.create!(name: "other_field")

    field_config = FieldConfig.new(
      screen: @screen,
      field: other_field,
      pinned_content: @content
    )

    assert_not field_config.valid?
    assert_includes field_config.errors[:field], "does not belong to the screen's template"
  end

  test "allows field that belongs to screen's template" do
    # Get a field that belongs to the screen's template
    position = @screen.template.positions.first
    field_config = FieldConfig.new(
      screen: @screen,
      field: position.field,
      pinned_content: @content
    )

    assert field_config.valid?
  end

  test "accepts valid ordering_strategy" do
    field_config = FieldConfig.new(
      screen: @screen,
      field: @field,
      ordering_strategy: "weighted"
    )

    assert field_config.valid?
  end

  test "rejects invalid ordering_strategy" do
    field_config = FieldConfig.new(
      screen: @screen,
      field: @field,
      ordering_strategy: "invalid_strategy"
    )

    assert_not field_config.valid?
    assert_includes field_config.errors[:ordering_strategy], "is not included in the list"
  end

  test "allows blank ordering_strategy" do
    field_config = FieldConfig.new(
      screen: @screen,
      field: @field,
      ordering_strategy: ""
    )

    assert field_config.valid?
  end

  test "allows nil ordering_strategy" do
    field_config = FieldConfig.new(
      screen: @screen,
      field: @field,
      ordering_strategy: nil
    )

    assert field_config.valid?
  end
end

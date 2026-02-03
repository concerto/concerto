require "test_helper"

class ScreenTest < ActiveSupport::TestCase
  test "online? returns true when last_seen_at is recent" do
    screen = screens(:one)
    screen.update_column(:last_seen_at, 1.minute.ago)
    assert screen.online?
  end

  test "online? returns false when last_seen_at is old" do
    screen = screens(:one)
    screen.update_column(:last_seen_at, 10.minutes.ago)
    assert_not screen.online?
  end

  test "online? returns false when last_seen_at is nil" do
    screen = screens(:one)
    screen.update_column(:last_seen_at, nil)
    assert_not screen.online?
  end

  test "config_version returns MD5 hash string" do
    screen = screens(:one)
    version = screen.config_version

    assert_kind_of String, version
    assert_equal 32, version.length
    assert_match(/^[a-f0-9]{32}$/, version)
  end

  test "config_version changes when screen is updated" do
    screen = screens(:one)
    old_version = screen.config_version

    travel 1.second do
      screen.update!(name: "Updated Name")
      new_version = screen.config_version

      assert_not_equal old_version, new_version
    end
  end

  test "config_version changes when template is updated" do
    screen = screens(:one)
    old_version = screen.config_version

    travel 1.second do
      screen.template.update!(name: "Updated Template")
      screen.reload
      new_version = screen.config_version

      assert_not_equal old_version, new_version
    end
  end

  test "config_version changes when position is updated" do
    screen = screens(:one)
    old_version = screen.config_version

    travel 1.second do
      position = screen.template.positions.first
      position.update!(top: 0.5)
      screen.reload
      new_version = screen.config_version

      assert_not_equal old_version, new_version
    end
  end

  test "config_version changes when field_config is created" do
    screen = screens(:one)
    old_version = screen.config_version

    travel 1.second do
      FieldConfig.create!(
        screen: screen,
        field: fields(:ticker),
        ordering_strategy: "weighted"
      )
      screen.reload
      new_version = screen.config_version

      assert_not_equal old_version, new_version
    end
  end

  test "config_version returns same hash for same timestamps" do
    screen = screens(:one)
    version1 = screen.config_version
    version2 = screen.config_version

    assert_equal version1, version2
  end

  test "config_version handles screen without field_configs" do
    screen = screens(:one)
    screen.field_configs.destroy_all

    assert_nothing_raised do
      version = screen.config_version
      assert_kind_of String, version
    end
  end

  test "config_version works with template that has attached image" do
    screen = screens(:one)

    # Ensure the template has an attached image
    assert screen.template.image.attached?, "Test requires template with attached image"

    # Should not raise an error
    assert_nothing_raised do
      version = screen.config_version
      assert_kind_of String, version
      assert_equal 32, version.length
    end
  end

  test "config_version changes when template image is replaced" do
    screen = screens(:one)

    # Skip if no image is attached
    skip "Template must have an attached image" unless screen.template.image.attached?

    old_version = screen.config_version

    travel 1.second do
      # Attach a new image (this creates a new attachment record)
      screen.template.image.attach(
        io: StringIO.new("new image content"),
        filename: "new_image.png",
        content_type: "image/png"
      )
      screen.reload
      new_version = screen.config_version

      assert_not_equal old_version, new_version, "Config version should change when image is replaced"
    end
  end
end

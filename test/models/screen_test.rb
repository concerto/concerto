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

  test "config_version does not change when only screen attributes are updated" do
    screen = screens(:one)
    old_version = screen.config_version

    travel 1.second do
      screen.update!(name: "Updated Name")
      new_version = screen.config_version

      assert_equal old_version, new_version
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

  test "switching to a template without a field keeps that field's config" do
    screen = screens(:one) # template :two, has main + sidebar field configs
    orphaned = field_configs(:without_pinned_content) # sidebar, not in template :one

    # template :one only lays out the main field; the save must still succeed
    # and the now-inert sidebar config is preserved, not deleted.
    assert screen.update(template: templates(:one)), screen.errors.full_messages.join(", ")

    assert FieldConfig.exists?(orphaned.id), "sidebar config should be preserved"
  end

  test "switching templates round-trip preserves field configs and their settings" do
    screen = screens(:one)
    sidebar_config = field_configs(:without_pinned_content) # sidebar
    sidebar_config.update!(ordering_strategy: "strict_priority")

    assert screen.update(template: templates(:one)) # no sidebar
    assert screen.update(template: templates(:two)) # sidebar again

    assert_equal "strict_priority", sidebar_config.reload.ordering_strategy
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

require "test_helper"

class ScreenTest < ActiveSupport::TestCase
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
end

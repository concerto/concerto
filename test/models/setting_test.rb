require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "requires key to be present" do
    setting = Setting.new(value: "test")
    assert_not setting.valid?
    assert_includes setting.errors[:key], "can't be blank"
  end

  test "requires key to be unique" do
    Setting.create!(key: "test_key", value: "value1")
    duplicate = Setting.new(key: "test_key", value: "value2")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:key], "has already been taken"
  end

  test "stores and retrieves string values" do
    Setting[:site_name] = "My Awesome App"
    assert_equal "My Awesome App", Setting[:site_name]
  end

  test "stores and retrieves integer values" do
    Setting[:items_per_page] = 20
    assert_equal 20, Setting[:items_per_page]
  end

  test "stores and retrieves array values" do
    emails = [ "a@b.com", "c@d.com" ]
    Setting[:admin_emails] = emails
    assert_equal emails, Setting[:admin_emails]
  end

  test "stores and retrieves boolean values" do
    Setting[:maintenance_mode] = true
    assert_equal true, Setting[:maintenance_mode]

    Setting[:maintenance_mode] = false
    assert_equal false, Setting[:maintenance_mode]
  end

  test "stores and retrieves hash values" do
    config = { "host" => "localhost", "port" => 3000 }
    Setting[:server_config] = config
    assert_equal config, Setting[:server_config]
  end

  test "returns nil for non-existent keys" do
    assert_nil Setting[:nonexistent_key]
  end

  test "updates existing settings" do
    Setting[:updateable] = "original"
    assert_equal "original", Setting[:updateable]

    Setting[:updateable] = "updated"
    assert_equal "updated", Setting[:updateable]
  end

  test "preserves types when updating existing settings" do
    # Test integer type preservation
    Setting[:number_setting] = 42
    Setting[:number_setting] = "15"  # Update with string
    assert_equal 15, Setting[:number_setting]  # Should be converted back to integer

    # Test boolean type preservation
    Setting[:flag_setting] = false
    Setting[:flag_setting] = "true"  # Update with string
    assert_equal true, Setting[:flag_setting]  # Should be converted to boolean

    # Test array type preservation
    Setting[:list_setting] = [ "first" ]
    Setting[:list_setting] = '["second"]'  # Update with JSON string
    assert_equal [ "second" ], Setting[:list_setting]  # Should be parsed as array

    # Test hash type preservation
    Setting[:config_setting] = { "key" => "value" }
    Setting[:config_setting] = '{"new":"config"}'  # Update with JSON string
    assert_equal({ "new" => "config" }, Setting[:config_setting])  # Should be parsed as hash
  end

  test "gracefully handles invalid JSON for array/hash settings" do
    # Set up valid array and hash settings
    Setting[:array_setting] = [ "valid" ]
    Setting[:hash_setting] = { "valid" => true }

    # Try updating with invalid JSON
    Setting[:array_setting] = "not valid json"
    Setting[:hash_setting] = "also not valid json"

    # Should default to empty array/hash rather than raising an error
    assert_equal [], Setting[:array_setting]
    assert_equal({}, Setting[:hash_setting])
  end

  test "uses cache for retrieving values" do
    Setting[:cached_key] = "cached value"

    # Value should be retrievable
    assert_equal "cached value", Setting[:cached_key]

    # Manually update the record to test cache invalidation
    setting = Setting.find_by(key: "cached_key")
    setting.update!(value: "new value")

    # Cache should be invalidated and new value retrieved
    assert_equal "new value", Setting[:cached_key]
  end
end

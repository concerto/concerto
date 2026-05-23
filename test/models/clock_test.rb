require "test_helper"

class ClockTest < ActiveSupport::TestCase
  setup do
    @admin = users(:admin)
  end

  test "valid clock with format" do
    clock = Clock.new(
      name: "Test Clock",
      duration: 10,
      format: "h:mm a",
      user: @admin
    )
    assert clock.valid?
  end

  test "requires format" do
    clock = Clock.new(
      name: "Test Clock",
      duration: 10,
      user: @admin
    )
    assert_not clock.valid?
    assert_includes clock.errors[:format], "can't be blank"
  end

  test "format must be a string" do
    clock = Clock.new(
      name: "Test Clock",
      duration: 10,
      user: @admin
    )
    clock.config = { format: [ "not", "a", "string" ] }
    assert_not clock.valid?
    assert_includes clock.errors[:format], "must be a string, not an array or other type"
  end

  test "as_json includes format" do
    clock = clocks(:time_12h)
    assert_equal "h:mm a", clock.format

    json = clock.as_json
    assert_equal "h:mm a", json[:format]  # Try symbol key instead of string key
  end

  test "locale is stored in config and round-trips" do
    clock = Clock.new(
      name: "Dutch Clock",
      duration: 10,
      format: "EEEE",
      locale: "nl",
      user: @admin
    )
    assert clock.valid?
    assert_equal "nl", clock.locale
    assert_equal "nl", clock.config["locale"]
  end

  test "locale is optional" do
    clock = Clock.new(
      name: "Default Clock",
      duration: 10,
      format: "h:mm a",
      user: @admin
    )
    assert clock.valid?
    assert_nil clock.locale
  end

  test "as_json includes locale (nil when blank)" do
    clock = clocks(:time_12h)
    assert_nil clock.as_json[:locale]

    clock.locale = "nl"
    assert_equal "nl", clock.as_json[:locale]

    # Blank strings normalize to nil so the player picks up the default
    clock.locale = ""
    assert_nil clock.as_json[:locale]
  end

  test "locale must be a string" do
    clock = Clock.new(
      name: "Test Clock",
      duration: 10,
      format: "h:mm a",
      user: @admin
    )
    clock.config = { format: "h:mm a", locale: [ "nl" ] }
    assert_not clock.valid?
    assert_includes clock.errors[:locale], "must be a string, not an array or other type"
  end

  test "formats class method returns hash of presets" do
    formats = Clock.formats
    assert_equal "h:mm a", formats[:time_12h]
    assert_equal "EEE, MMM d", formats[:date_short]
    assert_equal "h:mm a, MMM d", formats[:datetime_short]
  end
end

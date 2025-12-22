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

  test "formats class method returns hash of presets" do
    formats = Clock.formats
    assert_equal "h:mm a", formats[:time_12h]
    assert_equal "EEE, MMM d", formats[:date_short]
    assert_equal "h:mm a, MMM d", formats[:datetime_short]
  end
end

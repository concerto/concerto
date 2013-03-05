require 'test_helper'

class TickerTest < ActiveSupport::TestCase
  # Attributes cannot be left empty/blank
  test "ticker attributes must not be empty" do
    ticker = Ticker.new
    assert ticker.invalid?
    assert ticker.errors[:duration].any?
    assert ticker.errors[:data].any?
  end
  
  #Verify the kind is getting auto-assigned
  test "kind should be auto set" do
    ticker = Ticker.new
    assert_equal ticker.kind, Kind.where(name: "Ticker").first
  end

  test "ticker class has display name" do
    assert_equal Ticker.display_name, "Ticker Text"
  end
end

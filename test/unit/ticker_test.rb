require 'test_helper'

class TickerTest < ActiveSupport::TestCase
  # Attributes cannot be left empty/blank
  test "ticker attributes must not be empty" do
    ticker = Ticker.new
    assert ticker.invalid?
    assert ticker.errors[:duration].any?
  end
  
  #Verify the kind is getting auto-assigned
  test "kind should be auto set" do
    ticker = Ticker.new
    assert_equal ticker.kind, Kind.where(:name => "Ticker").first
  end
end

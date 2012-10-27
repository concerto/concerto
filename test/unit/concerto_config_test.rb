require 'test_helper'

class ConcertoConfigTest < ActiveSupport::TestCase
  #Test the fields that should be required
  test "Config must return a default upload type of graphic" do
    assert_equal(ConcertoConfig[:default_upload_type], "graphic")
    assert_equal(ConcertoConfig.get("default_upload_type"), "graphic")
  end

  #Test that we can create config entries.
  test "Make ConcertoConfig" do
    ConcertoConfig.make_concerto_config("foo123", "bar")
    assert_equal(ConcertoConfig[:foo123], "bar")
  end

  test "Set Config" do
    ConcertoConfig.set("default_upload_type", "ticker")
    assert_equal(ConcertoConfig[:default_upload_type], "ticker")
  end
end

require 'test_helper'

class ConcertoConfigTest < ActiveSupport::TestCase
  #Test the fields that should be required
  test "Config must return a default upload type of graphic" do
    assert_equal(ConcertoConfig[:default_upload_type], "graphic")
    assert_equal(ConcertoConfig.get("default_upload_type"), "graphic")
  end

  test "Booleans work as expected" do
    ConcertoConfig.set(:allow_user_screen_creation, true)
    assert ConcertoConfig[:allow_user_screen_creation]

    ConcertoConfig.set(:allow_user_screen_creation, false)
    assert !ConcertoConfig[:allow_user_screen_creation]
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

  test "set and get with cache" do
    ConcertoConfig.set('foo', 'bar')
    assert_equal(ConcertoConfig.get('foo'), 'bar')  # Trigger the cache rebuild.
    assert_equal(ConcertoConfig.cache_get('foo'), 'bar') # Verify the value.

    ConcertoConfig.set('foo', 'baz')
    assert_equal(ConcertoConfig.get('foo'), 'baz')
    assert_equal(ConcertoConfig.cache_get('foo'), 'baz')

    assert_equal(ConcertoConfig.cache_get('missing_key'), nil)
  end
end

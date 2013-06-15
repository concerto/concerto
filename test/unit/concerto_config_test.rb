require 'test_helper'

class ConcertoConfigTest < ActiveSupport::TestCase
  #Test the fields that should be required
  test "Config must return a default upload type of graphic" do
    assert_equal "graphic", ConcertoConfig[:default_upload_type]
    assert_equal "graphic", ConcertoConfig.get("default_upload_type")
  end

  #Test that we can create config entries.
  test "Make ConcertoConfig" do
    ConcertoConfig.make_concerto_config("foo123", "bar")
    assert_equal "bar", ConcertoConfig[:foo123]
  end

  test "Set Config" do
    ConcertoConfig.set("default_upload_type", "ticker")
    assert_equal "ticker", ConcertoConfig[:default_upload_type]
  end

  test "set and get with cache" do
    ConcertoConfig.set('foo', 'bar')
    assert_equal 'bar', ConcertoConfig.get('foo')  # Trigger the cache rebuild.
    assert_equal 'bar', ConcertoConfig.cache_get('foo') # Verify the value.

    ConcertoConfig.set('foo', 'baz')
    assert_equal 'baz', ConcertoConfig.get('foo')
    assert_equal 'baz', ConcertoConfig.cache_get('foo')

    assert_equal nil, ConcertoConfig.cache_get('missing_key')
  end
end

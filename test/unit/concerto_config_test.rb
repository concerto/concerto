require 'test_helper'

class ConcertoConfigTest < ActiveSupport::TestCase
  #Test the fields that should be required
  test "Config must return a default upload type of graphic" do
    assert_equal "graphic", ConcertoConfig[:default_upload_type]
    assert_equal "graphic", ConcertoConfig.get("default_upload_type")
  end

  test "Booleans work as expected" do
    ConcertoConfig.make_concerto_config(:allow_user_screen_creation, nil, { :value_type => 'boolean' })
    ConcertoConfig.set :allow_user_screen_creation, true
    assert ConcertoConfig[:allow_user_screen_creation]

    ConcertoConfig.set :allow_user_screen_creation, false
    assert !ConcertoConfig[:allow_user_screen_creation]
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
    assert_equal 'bar', ConcertoConfig.get('foo') # Trigger the cache rebuild.
    assert_equal 'bar', ConcertoConfig.cache_get('foo') # Verify the value.

    ConcertoConfig.set('foo', 'baz')
    assert_equal 'baz', ConcertoConfig.get('foo')
    assert_equal 'baz', ConcertoConfig.cache_get('foo')

    assert_nil ConcertoConfig.cache_get('missing_key')
  end

  test "entry whitelisting" do
    # whitelisted entry persists, nonlisted entry gets removed
    ConcertoConfig.make_concerto_config("whitelisted_key", "foo")
    ConcertoConfig.make_concerto_config("nonwhitelisted_key", "bar")

    ConcertoConfig::CONFIG_ITEMS.clear
    ConcertoConfig::CONFIG_ITEMS << 'whitelisted_key'

    ConcertoConfig::delete_unused_configs

    assert !ConcertoConfig.where(:key => 'whitelisted_key').empty?
    assert ConcertoConfig.where(:key => 'nonwhitelisted_key').empty?
  end

  test "key not found raises exception" do
    exception = assert_raises(RuntimeError) do
      ConcertoConfig[:this_key_doesnt_exist]
    end
    assert exception.message =~ /Concerto Config key .+ not found/
  end
end

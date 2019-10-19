require 'test_helper'

class VersionCheckTest < ActiveSupport::TestCase
  # regex comes from https://semver.org
  PATTERN=/^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/

  test 'STRING should match pattern' do
    assert PATTERN =~ Concerto::VERSION::STRING
  end

  test 'dynamic should match pattern' do
    Rails.cache.delete('VERSION::dynamic')
    assert PATTERN =~ Concerto::VERSION.dynamic
  end

  test 'version check latest version should match pattern' do
    Rails.cache.delete('concerto_version')
    Rails.cache.delete('concerto_version_time')
    v = VersionCheck.latest_version
    assert PATTERN =~ v, 'latest_verison does not match expected format'
    u = VersionCheck.latest_version
    assert v == u, "latest_version #{v} is not cached #{u}"
  end

  test 'latest version is cached for 24 hours' do
    Rails.cache.write('concerto_version', '1')
    Rails.cache.write('concerto_version_time', Time.now - 86300)
    v = VersionCheck.latest_version
    assert_equal '1', v

    Rails.cache.write('concerto_version_time', Time.now - 86500)
    v = VersionCheck.latest_version
    assert_not_equal '1', v
  end
end

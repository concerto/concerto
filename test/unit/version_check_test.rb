require 'test_helper'

class VersionCheckTest < ActiveSupport::TestCase
  test 'STRING should match pattern' do
    assert /[0-9].[0-9].[0-9]/ =~ Concerto::VERSION::STRING
  end

  test 'dynamic should match pattern' do
    Rails.cache.delete('VERSION::dynamic')
    assert /[0-9].[0-9].[0-9]-[0-9]{1,3}-[0-9a-z]+/ =~ Concerto::VERSION.dynamic
  end

  test 'version check latest version should match pattern' do
    Rails.cache.delete('concerto_version')
    Rails.cache.delete('concerto_version_time')
    v = VersionCheck.latest_version
    assert /[0-9].[0-9].[0-9]/ =~ v, 'latest_verison does not match expected format'

    assert v == VersionCheck.latest_version, 'latest_version is not cached'
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

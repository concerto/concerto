require 'test_helper'

class MacAddrTest < ActiveSupport::TestCase
  test 'to_i' do
    assert_equal 1829701878732, MacAddr.to_i('01:AA:02:BB:03:CC')
  end

  test 'to_hex' do
    assert_equal '01:aa:02:bb:03:cc', MacAddr.to_hex(1829701878732)
  end
end

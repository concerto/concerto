require 'test_helper'

class FrontendContentOrderTest < ActiveSupport::TestCase
  test 'default shuffler is BaseShuffle' do
    s = FrontendContentOrder.load_shuffler
    assert_equal BaseShuffle, s
  end

  test 'invalid shuffler results in default shuffler' do
    s = FrontendContentOrder.load_shuffler('BogusShuFFlerz')
    assert_equal BaseShuffle, s
  end
end

require 'test_helper'

class ShuffleIntegrationTest < ActionDispatch::IntegrationTest
  fixtures :all

  test 'returns expected content in expected order' do
    screen = screens(:one)
    field = fields(:one)
    subscriptions = screen.subscriptions.where(field_id: field.id)

    b = BaseShuffle.new(screen, field, subscriptions)
    n = b.next_contents

    assert_equal n.count, 2 # two pieces of content
    assert_equal n.first.name, 'Welcome Active Ticker2'
    assert_equal n.second.name, 'Welcome Active Ticker'
  end
end

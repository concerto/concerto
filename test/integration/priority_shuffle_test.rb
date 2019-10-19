require 'test_helper'

class PriorityShuffleIntegrationTest < ActionDispatch::IntegrationTest
  fixtures :all

  test 'returns level 2 priority content' do
    screen = screens(:one)
    field = fields(:one)
    subscriptions = screen.subscriptions.where(field_id: field.id)

    b = StrictPriorityShuffle.new(screen, field, subscriptions)
    n = b.next_contents

    # one item from priority 2, none from priority 1
    assert_equal n.count, 1 # only one and it should be the ...2
    assert_equal n.select { |e| e.name == 'Welcome Active Ticker2' }.count, 1
    assert_equal n.select { |e| e.name == 'Welcome Active Ticker' }.count, 0
  end

  test 'returns level 1 priority content' do
    screen = screens(:one)
    field = fields(:one)

    # remove content from the level 2 priority subscription
    content2 = contents(:active_ticker2)
    content2.destroy

    subscriptions = screen.subscriptions.where(field_id: field.id)

    b = StrictPriorityShuffle.new(screen, field, subscriptions)
    n = b.next_contents

    # one item from priority 1, none from priority 2
    assert_equal n.count, 1 # only one and it should be the ...2
    assert_equal n.select { |e| e.name == 'Welcome Active Ticker2' }.count, 0
    assert_equal n.select { |e| e.name == 'Welcome Active Ticker' }.count, 1
  end
end

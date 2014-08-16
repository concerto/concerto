require 'test_helper'

class ScreenFeedAbilityTest < ActiveSupport::TestCase

  test "screens can read subscribed feed that is otherwise unreadble" do
    ConcertoConfig.set('public_concerto', false)

    screen = screens(:three)
    feed = feeds(:invisible_feed)

    ability = Ability.new(screen)
    assert !ability.can?(:read, feed), "Should not be able to read feed"

    s = Subscription.new
    s.feed = feed
    s.screen = screen
    s.field = fields(:one)

    s.save!
    screen.reload

    ability = Ability.new(screen)
    assert ability.can?(:read, feed), "Should be able to read feed"

    ConcertoConfig.set('public_concerto', true)
  end
end

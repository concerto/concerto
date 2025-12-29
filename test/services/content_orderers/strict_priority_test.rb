# frozen_string_literal: true

require "test_helper"

class ContentOrderers::StrictPriorityTest < ActiveSupport::TestCase
  test "returns only highest-weighted content" do
    content1 = rich_texts(:html_richtext)
    content2 = graphics(:one)
    content3 = videos(:video_youtube)

    sub_high = Subscription.new(
      screen: screens(:one),
      field: fields(:main),
      feed: feeds(:one),
      weight: 10
    )
    sub_medium = Subscription.new(
      screen: screens(:one),
      field: fields(:main),
      feed: feeds(:two),
      weight: 5
    )
    sub_low = Subscription.new(
      screen: screens(:one),
      field: fields(:sidebar),
      feed: feeds(:one),
      weight: 2
    )

    items = [
      { content: content1, subscription: sub_high },
      { content: content2, subscription: sub_medium },
      { content: content3, subscription: sub_low }
    ]

    orderer = ContentOrderers::StrictPriority.new
    result = orderer.call(items)

    # Should only include content from highest weight subscription
    assert_equal 1, result.length
    assert_equal content1, result.first
  end

  test "returns all content with same highest weight" do
    content1 = rich_texts(:html_richtext)
    content2 = graphics(:one)
    content3 = videos(:video_youtube)

    sub_high1 = Subscription.new(
      screen: screens(:one),
      field: fields(:main),
      feed: feeds(:one),
      weight: 10
    )
    sub_high2 = Subscription.new(
      screen: screens(:one),
      field: fields(:main),
      feed: feeds(:two),
      weight: 10
    )
    sub_low = Subscription.new(
      screen: screens(:one),
      field: fields(:sidebar),
      feed: feeds(:one),
      weight: 2
    )

    items = [
      { content: content1, subscription: sub_high1 },
      { content: content2, subscription: sub_high2 },
      { content: content3, subscription: sub_low }
    ]

    orderer = ContentOrderers::StrictPriority.new
    result = orderer.call(items)

    # Should include both high-priority items, but not the low one
    assert_equal 2, result.length
    assert_includes result, content1
    assert_includes result, content2
    refute_includes result, content3
  end

  test "handles empty array" do
    orderer = ContentOrderers::StrictPriority.new
    result = orderer.call([])

    assert_equal [], result
  end

  test "handles single item" do
    content = rich_texts(:html_richtext)
    subscription = Subscription.new(
      screen: screens(:one),
      field: fields(:main),
      feed: feeds(:one),
      weight: 5
    )

    items = [ { content: content, subscription: subscription } ]

    orderer = ContentOrderers::StrictPriority.new
    result = orderer.call(items)

    assert_equal 1, result.length
    assert_equal content, result.first
  end

  test "returns only content objects not hashes" do
    content = rich_texts(:html_richtext)
    subscription = Subscription.new(
      screen: screens(:one),
      field: fields(:main),
      feed: feeds(:one),
      weight: 5
    )

    items = [ { content: content, subscription: subscription } ]

    orderer = ContentOrderers::StrictPriority.new
    result = orderer.call(items)

    assert_equal 1, result.length
    assert_instance_of RichText, result.first
  end

  test "shuffles content within same priority level" do
    content1 = rich_texts(:html_richtext)
    content2 = graphics(:one)
    content3 = videos(:video_youtube)

    sub1 = Subscription.new(
      screen: screens(:one),
      field: fields(:main),
      feed: feeds(:one),
      weight: 10
    )
    sub2 = Subscription.new(
      screen: screens(:one),
      field: fields(:main),
      feed: feeds(:two),
      weight: 10
    )
    sub3 = Subscription.new(
      screen: screens(:one),
      field: fields(:sidebar),
      feed: feeds(:one),
      weight: 10
    )

    items = [
      { content: content1, subscription: sub1 },
      { content: content2, subscription: sub2 },
      { content: content3, subscription: sub3 }
    ]

    orderer = ContentOrderers::StrictPriority.new

    # Run multiple times to check for different orderings
    results = 10.times.map { orderer.call(items) }

    # At least one result should be different from the first
    assert results.any? { |result| result != results.first },
           "Expected shuffling within same priority level"
  end
end

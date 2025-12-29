# frozen_string_literal: true

require "test_helper"

class ContentOrderers::RandomTest < ActiveSupport::TestCase
  test "returns all content items" do
    content1 = rich_texts(:html_richtext)
    content2 = graphics(:one)
    subscription = subscriptions(:one)

    items = [
      { content: content1, subscription: subscription },
      { content: content2, subscription: subscription }
    ]

    orderer = ContentOrderers::Random.new
    result = orderer.call(items)

    assert_equal 2, result.length
    assert_includes result, content1
    assert_includes result, content2
  end

  test "shuffles content order" do
    # Create multiple unique content items
    subscription = subscriptions(:one)
    contents_array = (1..10).map do |i|
      RichText.create!(
        name: "Test Content #{i}",
        text: "Content #{i}" * 20,
        user: users(:admin),
        duration: 10,
        config: { render_as: "plaintext" }
      )
    end

    items = contents_array.map do |content|
      { content: content, subscription: subscription }
    end

    orderer = ContentOrderers::Random.new

    # Run multiple times and check that we get different orders
    results = 10.times.map { orderer.call(items) }

    # At least one result should be different from the first
    # (statistically very likely with 10 items shuffled 10 times)
    assert results.any? { |result| result != results.first },
           "Expected at least one different ordering"
  end

  test "handles empty array" do
    orderer = ContentOrderers::Random.new
    result = orderer.call([])

    assert_equal [], result
  end

  test "returns only content objects not hashes" do
    content = rich_texts(:html_richtext)
    subscription = subscriptions(:one)

    items = [ { content: content, subscription: subscription } ]

    orderer = ContentOrderers::Random.new
    result = orderer.call(items)

    assert_equal 1, result.length
    assert_instance_of RichText, result.first
    assert_equal content, result.first
  end
end

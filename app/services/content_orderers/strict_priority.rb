# frozen_string_literal: true

module ContentOrderers
  # Shows only content from the highest-weighted subscription(s).
  #
  # This strategy filters content to include only items from subscriptions with
  # the maximum weight. If multiple subscriptions share the highest weight, content
  # from all of them will be included and shuffled randomly.
  #
  # Use case: Emergency broadcasts or situations where you only want to display
  # the most critical content.
  #
  # Example:
  #   # With weights: Feed A (10), Feed B (5), Feed C (5)
  #   # Only content from Feed A will be shown
  #   orderer = ContentOrderers::StrictPriority.new
  #   ordered_content = orderer.call(content_items)
  class StrictPriority < Base
    def call(content_items)
      return [] if content_items.empty?

      max_weight = content_items.map { |item| item[:subscription].weight }.max

      content_items
        .select { |item| item[:subscription].weight == max_weight }
        .shuffle
        .map { |item| item[:content] }
    end
  end
end

# frozen_string_literal: true

module ContentOrderers
  # Orders content based on subscription weight, with higher-weighted content appearing more frequently.
  #
  # This strategy duplicates each content item according to its subscription's weight (1-10),
  # then shuffles the result and removes consecutive duplicates. Higher-weighted subscriptions
  # will appear more often in the final output, but the exact ratio depends on the shuffle
  # and deduplication process.
  #
  # Use case: When you want to give priority to certain feeds while still showing content
  # from all subscribed feeds.
  #
  # Example:
  #   # Feed A (weight: 6) will appear roughly 3x as often as Feed B (weight: 2)
  #   orderer = ContentOrderers::Weighted.new
  #   ordered_content = orderer.call(content_items)
  class Weighted < Base
    def call(content_items)
      weighted = content_items.flat_map do |item|
        Array.new(item[:subscription].weight, item[:content])
      end

      remove_consecutive_duplicates(weighted.shuffle)
    end

    private

    def remove_consecutive_duplicates(items)
      items.chunk_while { |a, b| a.id == b.id }.map(&:first)
    end
  end
end

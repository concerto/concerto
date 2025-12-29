# frozen_string_literal: true

module ContentOrderers
  # Base class for content ordering strategies.
  #
  # Content orderers determine the sequence in which content items are displayed
  # on screen fields. Each orderer receives an array of content items with their
  # associated subscription metadata and returns an ordered array of content objects.
  #
  # Subclasses should override the #call method to implement specific ordering logic.
  class Base
    # @param content_items [Array<Hash>] Array of { content:, subscription: } hashes
    # @return [Array<Content>] Ordered content items
    def call(content_items)
      content_items.map { |item| item[:content] }
    end
  end
end

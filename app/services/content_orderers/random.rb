# frozen_string_literal: true

module ContentOrderers
  # Shuffles content items randomly to provide variety in content display.
  #
  # This is the default ordering strategy. It ensures fair distribution and
  # prevents predictable patterns in content playback.
  #
  # Example:
  #   orderer = ContentOrderers::Random.new
  #   ordered_content = orderer.call(content_items)
  class Random < Base
    def call(content_items)
      content_items.shuffle.map { |item| item[:content] }
    end
  end
end

# Implement a simple Base Shuffle algorithm.
# A simple approach that just grabs all the content
# without shuffling it or weighing it.
class BaseShuffle
  # Initialize all the variables, setup a store if needed.
  #
  # @param [Screen] screen Screen showing the content.
  # @param [Field] field Field showing the content.
  # @param [Array<Subscription>] subscriptions All the subscriptions to use.
  # @param [Hash] options Any additional options.
  def initialize(screen, field, subscriptions, options = {})
    @screen = screen
    @field = field
    @subscriptions = subscriptions
    @options = options
  end

  # Return the next set content to be shown.
  #
  # @return [Array<Content>] Next content that should be rendered.
  def next_contents
    content.to_a.compact
  end

  def remove_consecutive(arr)
    last_item = nil
    arr.map do |a|
      keep = last_item.nil? || last_item != a
      last_item = a
      keep ? a : nil
    end.compact
  end

  private

  def content
    @subscriptions.collect{|s| s.contents.order('submissions.seq_no, submissions.id')}).flatten
  end
end

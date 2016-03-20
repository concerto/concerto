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
  def initialize(screen, field, subscriptions, options={})
    @screen = screen
    @field = field
    @subscriptions = subscriptions
    @options = options
  end

  # Return the next set content to be shown.
  #
  # @return [Array<Content>] Next content that should be rendered.
  def next_contents()
    content.to_a.compact
  end

  private

  def content
    @subscriptions.collect{|s| s.contents }.flatten
  end
end

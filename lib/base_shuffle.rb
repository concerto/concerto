# Implement a simple Base Shuffle algorithm.
# A simple approach that just grabs all the content
# without shuffling it or weighing it.
class BaseShuffle
  # Initialze all the variables, setup a store if needed.
  #
  # @param [Screen] screen Screen showing the content.
  # @param [Field] field Field showing the content.
  # @param [Array<Subscription>] subscriptions All the subscriptions to use.
  # @param [Array<Integer>] store Array to store a timeline if needed.
  # @param [Hash] options Any additional options. 
  def initialize(screen, field, subscriptions, store=[], options={})
    @screen = screen
    @field = field
    @subscriptions = subscriptions
    @store = store
    @options = options

    @store = [] if @store.nil?
  end

  # Return the next set content to be shown.
  #
  # @param [Integer] count Number of content needed, defaults to 1.
  # @return [Array<Content>] Next content that should be rendered.
  def next_contents(count=1)
    if @store.length < count
      content = content()
      @store += content.collect{|c| c.id}
    end
    return [] if @store.empty?
    return @store.pop(count).collect{|id| Content.find(id)}
  end

  # Return a timeline to be saved.
  # Since we can't directly access the session, the controller
  # will pull here for what should be saved.
  #
  # @returns [Array<Integer>] Array of content ids in the timeline.
  def save_session()
    @store
  end

  private

  def content
    @subscriptions.collect{|s| s.contents }.flatten
  end
end

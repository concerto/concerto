class ContentShuffler

  def initialize(unused_screen, unused_field, subscriptions, store=[], options={})
    @subscriptions = subscriptions
    @store = store

    @store = [] if @store.nil?
  end

  def next_contents(count=1)
    if @store.length < count
      content = weighted_content()
      @store += content.collect{|c| c.id}
    end
    return [] if @store.empty?
    return @store.pop(count).collect{|id| Content.find(id)}
  end

  def save_session()
    @store
  end

  private

  def weighted_content
    @subscriptions.collect{|s| s.contents * s.weight}.flatten.shuffle!
  end
end

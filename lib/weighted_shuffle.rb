require 'base_shuffle'

# Weight and shuffle the content.
# Uses a weighting and shuffling approach similiar to Concerto 1,
# where content is added N times for the weight of each subscription
# then jumbled up and served from a timeline.
class WeightedShuffle < BaseShuffle

  def next_contents(count=1)
    if @store.length < count
      content = weighted_content()
      @store += content.collect{|c| c.id}
    end
    return [] if @store.empty?

    content_ids = @store.shift(count)
    Content.where(:id => content_ids).compact
  end

  private

  def weighted_content
    @subscriptions.collect{|s| s.contents * (!s.weight.nil? ? s.weight : 1)}.flatten.shuffle!
  end
end

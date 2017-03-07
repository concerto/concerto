require 'base_shuffle'

# Weight and shuffle the content.
# Uses a weighting and shuffling approach similiar to Concerto 1,
# where content is added N times for the weight of each subscription
# then jumbled up and served from a timeline.
class StrictPriorityShuffle < BaseShuffle

  def next_contents()
    prioritised_content.to_a.compact
  end

  private

  def prioritised_content
    highest_prio=@subscriptions.select{|s| s.contents.length>0}.max_by{|s| s.weight}.weight
    @subscriptions.select{|s| s.weight==highest_prio}.collect{|s| s.contents}.flatten.shuffle
  end
end

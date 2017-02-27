require 'base_shuffle'

# Weight and shuffle the content.
# includes only content belonging to the highest weighted subscription
class StrictPriorityShuffle < BaseShuffle
  def next_contents
    prioritised_content.to_a.compact
  end

  private

  def prioritised_content
    highest_priority = @subscriptions.select { |s| s.contents.present? }.max_by(&:weight).weight
    @subscriptions.select { |s| s.weight == highest_priority }.collect(&:contents).flatten.shuffle
  end
end

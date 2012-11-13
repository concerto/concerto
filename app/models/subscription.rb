class Subscription < ActiveRecord::Base
  # Weight Levels
  WEIGHTS = {
    # A very frequent chance of content showing up.
    :"very frequent" => 5,
    # A frequent chance of content showing up.
    :frequent => 4,
    # Neither a frequent, nor a infrequence chance of
    # content showing up.
    :netural => 3,
    # An infrequent chance of content showing up.
    :infrequent => 2,
    # A very infrequent chance of content showing up.
    :"very infrequent" => 1,
  }
  # Associations
  belongs_to :feed
  belongs_to :field
  belongs_to :screen
  
  #Validations
  validates :feed, :presence => true, :associated => true
  validates_uniqueness_of :feed_id, :scope => [:screen_id, :field_id]

  #Get weight name of a subscription
  def weight_name
    name = (Subscription::WEIGHTS.respond_to?(:key) ? Subscription::WEIGHTS.key(weight) :  Subscription::WEIGHTS.index(weight)).to_s
  end
end

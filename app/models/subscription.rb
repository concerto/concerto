class Subscription < ActiveRecord::Base
  belongs_to :feed
  belongs_to :field
  belongs_to :screen
  
  #Validations
  validates :feed, :presence => true, :associated => true
  validates_uniqueness_of :feed_id, :scope => [:screen_id, :field_id]
end

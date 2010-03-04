class Submission < ActiveRecord::Base
  belongs_to :content
  belongs_to :feed
  belongs_to :moderator, :class_name => "User"
  
  #Validations
  validates :feed, :presence => true, :associated => true
  validates :content, :presence => true, :associated => true
  validates :moderator, :associated => true
  validates_uniqueness_of :content_id, :scope => :feed_id  #Enforce content can only be submitted to a feed once

  #Scoping shortcuts for active/denied/pending
  scope :approved, where(:moderation_flag => true)
  scope :denied, where(:moderation_flag => false)
  scope :pending, where("moderation_flag IS NULL") 
end

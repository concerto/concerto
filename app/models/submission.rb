class Submission < ActiveRecord::Base
  belongs_to :content
  belongs_to :feed
  belongs_to :user
  
  #Validations
  validates :feed, :presence => true, :associated => true
  validates :content, :presence => true, :associated => true

  #Scoping shortcuts for active/denied/pending
  scope :approved, where(:moderation_flag => true)
  scope :denied, where(:moderation_flag => false)
  scope :pending, where("moderation_flag IS NULL") 
end

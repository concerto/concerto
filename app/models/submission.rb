class Submission < ActiveRecord::Base
  belongs_to :content
  belongs_to :feed
  belongs_to :user
  
  #Validations
  validates_associated :feed, :content

  #Scoping shortcuts for active/denied/pending
  scope :approved, where(:moderation_flag => true)
  scope :denied, where(:moderation_flag => true)
  scope :pending, where("moderation_flag IS NULL") 
end

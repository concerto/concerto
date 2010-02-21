class Submission < ActiveRecord::Base
  belongs_to :content
  belongs_to :feed
  belongs_to :user
  
  #Validations
  validates_associated :feed, :content
end

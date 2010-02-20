class Submission < ActiveRecord::Base
  belongs_to :content
  belongs_to :feed
  belongs_to :user
end

class Submission < ApplicationRecord
  belongs_to :content
  belongs_to :feed
end

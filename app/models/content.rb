class Content < ApplicationRecord
    has_many :submissions, dependent: :destroy
    has_many :feeds, through: :submissions
end

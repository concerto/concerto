class Feed < ApplicationRecord
    has_many :submissions, dependent: :destroy
    has_many :content, through: :submissions

    has_many :subscriptions
end

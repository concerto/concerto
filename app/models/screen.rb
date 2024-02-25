class Screen < ApplicationRecord
  belongs_to :template

  has_many :subscriptions, dependent: :destroy
end

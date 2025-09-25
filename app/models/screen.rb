class Screen < ApplicationRecord
  belongs_to :template
  belongs_to :group

  has_many :subscriptions, dependent: :destroy
end

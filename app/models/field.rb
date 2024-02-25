class Field < ApplicationRecord
    has_many :positions

    serialize :alt_names, coder: JSON, type: Array

    has_many :subscriptions
end

class Field < ApplicationRecord
    has_many :positions, dependent: :restrict_with_error
    has_many :subscriptions, dependent: :restrict_with_error
    has_many :field_configs, dependent: :restrict_with_error

    serialize :alt_names, coder: JSON, type: Array

    validates :name, presence: true, uniqueness: { case_sensitive: false }

    # True when this field is referenced by a template position, a screen
    # subscription, or a field config and therefore cannot be deleted.
    def in_use?
      positions.exists? || subscriptions.exists? || field_configs.exists?
    end
end

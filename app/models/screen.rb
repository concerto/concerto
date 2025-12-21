class Screen < ApplicationRecord
  belongs_to :template
  belongs_to :group

  has_many :subscriptions, dependent: :destroy
  has_many :field_configs, dependent: :destroy

  accepts_nested_attributes_for :field_configs,
    allow_destroy: true,
    reject_if: ->(attributes) {
      # For new records, reject if only metadata fields are present (no actual config)
      if attributes["id"].blank?
        # Metadata fields that don't count as "config"
        metadata = %w[id _destroy field_id screen_id]
        # Get all non-metadata attribute keys
        config_attrs = attributes.keys - metadata
        # Reject if all config attributes are blank
        config_attrs.all? { |key| attributes[key].blank? }
      else
        false  # Never reject existing records (allows clearing)
      end
    }

  validates :name, presence: true
end

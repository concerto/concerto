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

  # Returns an MD5 hash of the most recent configuration change timestamp.
  # This is used by the frontend to detect when the screen configuration has changed
  # and trigger a reload.
  def config_version
    timestamps = [
      updated_at,
      template.updated_at,
      template.positions.map(&:updated_at).max,
      field_configs.map(&:updated_at).max,
      template.image.attachment&.updated_at
    ].compact

    max_timestamp = timestamps.max
    Digest::MD5.hexdigest(max_timestamp.to_s)
  end
end

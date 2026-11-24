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

  ONLINE_THRESHOLD = 5.minutes
  HEARTBEAT_INTERVAL = 1.minute

  def online?
    last_seen_at.present? && last_seen_at > ONLINE_THRESHOLD.ago
  end

  # Updates last_seen_at at most once per HEARTBEAT_INTERVAL to avoid SQLite
  # write lock contention on frequent player polls without mutating updated_at.
  def record_heartbeat!
    return unless last_seen_at.nil? || last_seen_at < HEARTBEAT_INTERVAL.ago

    update_column(:last_seen_at, Time.current)
  end

  # Returns an MD5 hash of the screen's layout and field configuration state.
  # This is used by the frontend to detect when the screen configuration has
  # changed (including template switches and position/field_config deletions)
  # and trigger a reload. Uses already-preloaded associations in Ruby so it
  # does not trigger extra queries on frontend polls.
  def config_version
    fingerprint = [
      template_id,
      template.updated_at&.iso8601(6),
      template.image.attachment&.created_at&.iso8601(6),
      template.positions.sort_by { |p| p.id.to_i }.map { |p| [ p.id, p.updated_at&.iso8601(6) ] },
      field_configs.sort_by { |fc| fc.id.to_i }.map { |fc| [ fc.id, fc.updated_at&.iso8601(6) ] }
    ]

    Digest::MD5.hexdigest(fingerprint.to_json)
  end
end

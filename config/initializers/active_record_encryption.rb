# Derive ActiveRecord::Encryption keys from the application's secret_key_base
# so no additional environment variables are required.
generator = Rails.application.key_generator

Rails.application.config.active_record.encryption.primary_key =
  generator.generate_key("active_record_encryption/primary_key", 32)
Rails.application.config.active_record.encryption.deterministic_key =
  generator.generate_key("active_record_encryption/deterministic_key", 32)
Rails.application.config.active_record.encryption.key_derivation_salt =
  generator.generate_key("active_record_encryption/key_derivation_salt", 32)

Rails.logger.debug "Starting #{File.basename(__FILE__)} at #{Time.now.to_s}"

secret_token = ENV['SECRET_TOKEN']

if secret_token.blank? 
  if ActiveRecord::Base.connection.table_exists?('concerto_configs')
    # Try go get secret key from concerto config or auto-generate it
    secret_token = ConcertoConfig[:secret_token]
  end
end

if secret_token.blank?
  require 'securerandom'
  secret_token = SecureRandom.hex(64)
  Rails.logger.debug 'Auto-generated secret token'

  if ActiveRecord::Base.connection.table_exists?('concerto_configs')
    ConcertoConfig.set('secret_token', secret_token)
  end
end

# Secret key for verifying the integrity of signed cookies.
Concerto::Application.config.secret_token = secret_token
Concerto::Application.config.secret_key_base = secret_token
ENV["SECRET_KEY_BASE"] = secret_token

Rails.logger.debug "Completed #{File.basename(__FILE__)} at #{Time.now.to_s}"

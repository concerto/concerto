Rails.logger.debug "Starting #{File.basename(__FILE__)} at #{Time.now.to_s}"

require 'yaml'
concerto_base_config = YAML.load_file('./config/concerto.yml')

if ActiveRecord::Base.connection.table_exists? 'concerto_configs'
  ConcertoConfig.make_concerto_config('send_errors',
    "#{concerto_base_config['airbrake_enabled_initially'].to_s}",
    value_type: 'boolean', category: 'System')

  if defined?(Airbrake)
    Airbrake.configure do |config|
      config.project_key = '34e36775df3e89293c59efeba36f6c8f'
      config.project_id = 1
      config.host = 'http://errors.concerto-signage.org:80'
      config.environment = Concerto::VERSION::STRING

      # Uncomment the following to start reporting development mode errors.
      # config.ignore_environments = []
    end
  end
end

Rails.logger.debug "Completed #{File.basename(__FILE__)} at #{Time.now.to_s}"

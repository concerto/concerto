Rails.logger.debug "Starting 13-airbrake.rb at #{Time.now.to_s}"

require 'yaml'
concerto_base_config = YAML.load_file("./config/concerto.yml")

if ActiveRecord::Base.connection.table_exists? 'concerto_configs'
  ConcertoConfig.make_concerto_config("send_errors", "#{concerto_base_config['airbrake_enabled_initially'].to_s}", :value_type => "boolean", :category => "System")

  if defined?(Airbrake)
    Airbrake.configure do |config|
      def config.api_key
        if ConcertoConfig[:send_errors] == true
          return '52adf2979c2ab87c634612bef9deaaf2'
        else 
          return nil
        end
      end
      #config.async = (RUBY_VERSION.to_f > 1.8)
      config.user_attributes = []
      config.secure = true
      config.environment_name = Concerto::VERSION::STRING

      # Uncomment the following to start reporting development mode errors.
      #config.development_environments = []
    end
  end
end

Rails.logger.debug "Completed 13-airbrake.rb at #{Time.now.to_s}"

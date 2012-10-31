if ActiveRecord::Base.connection.table_exists? 'concerto_configs'
  if ConcertoConfig.columns_hash.has_key?("plugin_id")
    ConcertoConfig.make_concerto_config("allow_remote_error_reporting", "true", :value_type => "boolean")
  end
end

Airbrake.configure do |config|
  def config.api_key
    if ConcertoConfig[:allow_remote_error_reporting] == "true"
      return '52adf2979c2ab87c634612bef9deaaf2'
    else 
      return nil
    end
  end
  config.async = (RUBY_VERSION.to_f > 1.8)
  config.user_attributes = []
  config.secure = true
  
  # Uncomment the following to start reporting development mode errors.
  #config.development_environments = []
end

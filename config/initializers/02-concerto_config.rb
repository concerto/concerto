Rails.logger.debug "Starting 02-concerto_config.rb at #{Time.now.to_s}"

#Initialize all core Concerto Config entries

if ActiveRecord::Base.connection.table_exists? 'concerto_configs'
  if ConcertoConfig.columns_hash.has_key?("plugin_id")
    ConcertoConfig.make_concerto_config("default_upload_type", "graphic")
    ConcertoConfig.make_concerto_config("public_concerto", "true", :value_type => "boolean")
    ConcertoConfig.make_concerto_config("content_default_start_time", "12:00 am")
    ConcertoConfig.make_concerto_config("content_default_end_time", "11:59 pm")
    ConcertoConfig.make_concerto_config("start_date_offset", "0", :value_type => "integer")
    ConcertoConfig.make_concerto_config("default_content_run_time", "7", :value_type => "integer")
    ConcertoConfig.make_concerto_config("setup_complete", "false", :value_type => "boolean", :value_default => "true", :hidden => "true")
    ConcertoConfig.make_concerto_config("allow_registration", "true", :value_type => "boolean")
    ConcertoConfig.make_concerto_config("allow_user_screen_creation", "false", :value_type => "boolean")
    ConcertoConfig.make_concerto_config("allow_user_feed_creation", "true", :value_type => "boolean")
    ConcertoConfig.make_concerto_config("rubygem_executable", "gem")
    ConcertoConfig.make_concerto_config("autostart_delayed_job", "true", :value_type => "boolean")
    ConcertoConfig.make_concerto_config("dynamic_refresh_time", "0", :value_type => "integer", :hidden => "true")
    ConcertoConfig.make_concerto_config("use_frontend_to_trigger_cron", "false", :value_type => "boolean")
    ConcertoConfig.make_concerto_config("default_content_duration", "8", :value_type => "integer")
    ConcertoConfig.make_concerto_config("max_content_duration", "12", :value_type => "integer")
    ConcertoConfig.make_concerto_config("min_content_duration", "4", :value_type => "integer")   
    ConcertoConfig.make_concerto_config("mailer_protocol", "sendmail")
    ConcertoConfig.make_concerto_config("mailer_host", "#{`hostname -f`.strip}")
    ConcertoConfig.make_concerto_config("smtp_address", "")
    ConcertoConfig.make_concerto_config("smtp_port", "587", :value_type => "integer")
    ConcertoConfig.make_concerto_config("smtp_auth_type", "plain")
    ConcertoConfig.make_concerto_config("smtp_username", "")
    ConcertoConfig.make_concerto_config("smtp_password", "")  
  end
end

Rails.logger.debug "Completed 02-concerto_config.rb at #{Time.now.to_s}"

Rails.logger.debug "Starting 02-concerto_config.rb at #{Time.now.to_s}"

#Initialize all core Concerto Config entries
require 'socket'
begin
  concerto_hostname = Socket.gethostbyname(Socket.gethostname).first
rescue SocketError => e
  concerto_hostname = ""
  Rails.logger.debug "Socket error in trying to determine hostname: #{e}"
end

if ActiveRecord::Base.connection.table_exists? 'concerto_configs'
  if ConcertoConfig.columns_hash.has_key?("plugin_id")
    # defaults
    ConcertoConfig.make_concerto_config("default_upload_type", "graphic", :group => 'Content')
    ConcertoConfig.make_concerto_config("content_default_start_time", "12:00 am", :group => 'Content')
    ConcertoConfig.make_concerto_config("content_default_end_time", "11:59 pm", :group => 'Content')
    ConcertoConfig.make_concerto_config("start_date_offset", "0", :value_type => "integer", :group => 'Content')
    ConcertoConfig.make_concerto_config("default_content_run_time", "7", :value_type => "integer", :group => 'Content')
    ConcertoConfig.make_concerto_config("default_content_duration", "8", :value_type => "integer", :group => 'Content')
    ConcertoConfig.make_concerto_config("max_content_duration", "12", :value_type => "integer", :group => 'Content')
    ConcertoConfig.make_concerto_config("min_content_duration", "4", :value_type => "integer", :group => 'Content')

    # access
    ConcertoConfig.make_concerto_config("public_concerto", "true", :value_type => "boolean", :group => 'Permissions', :seq_no => 99)
    ConcertoConfig.make_concerto_config("allow_registration", "true", :value_type => "boolean", :group => 'Permissions', :seq_no => 1)
    ConcertoConfig.make_concerto_config("confirmable", "false", :value_type => "boolean", :group => 'Permissions', :seq_no => 2)
    ConcertoConfig.make_concerto_config("allow_user_screen_creation", "false", :value_type => "boolean", :group => 'Permissions', :seq_no => 99)
    ConcertoConfig.make_concerto_config("allow_user_feed_creation", "true", :value_type => "boolean", :group => 'Permissions', :seq_no => 99)

    # mail
    ConcertoConfig.make_concerto_config("mailer_protocol", "sendmail", :value_type => "string", :group => 'Mail', :seq_no => 1)
    ConcertoConfig.make_concerto_config("mailer_from", "concerto@localhost", :value_type => "string", :value_default => "concerto@localhost", :group => 'Mail', :seq_no => 2)
    ConcertoConfig.make_concerto_config("mailer_host", concerto_hostname, :value_type => "string", :value_default => concerto_hostname, :group => 'Mail', :seq_no => 3)
    ConcertoConfig.make_concerto_config("smtp_address", "", :value_type => "string", :group => 'Mail', :seq_no => 4)
    ConcertoConfig.make_concerto_config("smtp_port", "587", :value_type => "integer", :value_default => 587, :group => 'Mail', :seq_no => 5)
    ConcertoConfig.make_concerto_config("smtp_auth_type", "plain", :value_type => "string", :value_default => "plain", :group => 'Mail', :seq_no => 6)
    ConcertoConfig.make_concerto_config("smtp_username", "", :value_type => "string", :group => 'Mail', :seq_no => 7)
    ConcertoConfig.make_concerto_config("smtp_password", "", :value_type => "string", :group => 'Mail', :seq_no => 8)
    ConcertoConfig.make_concerto_config("openssl_verify_mode_none", "false", :value_type => "boolean", :value_default => "false", :group => 'Mail', :seq_no => 9)

    # background processing
    ConcertoConfig.make_concerto_config("worker_heartbeat", "0", :value_type => "integer", :group => 'Processing', :hidden => "true", :can_cache => false)

    # system
    ConcertoConfig.make_concerto_config("setup_complete", "false", :value_type => "boolean", :value_default => "true", :hidden => "true", :group => 'System')
    ConcertoConfig.make_concerto_config("system_time_zone", 'Eastern Time (US & Canada)', :value_type => "timezone", :group => 'System') 
    ConcertoConfig.make_concerto_config("config_last_updated", "0", :value_type => "integer", :hidden => "true", :group => 'System')
  end

  Rails.logger.debug "Completed 02-concerto_config.rb at #{Time.now.to_s}"
  
  #Set the time here instead of in application.rb to get ConcertoConfig access
  Rails.application.config.time_zone = ConcertoConfig[:system_time_zone]
  #Set Time.zone specifically, because it's too late to derive it from config.
  Time.zone = ConcertoConfig[:system_time_zone]
end

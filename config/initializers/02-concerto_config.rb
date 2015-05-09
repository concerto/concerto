Rails.logger.debug "Starting #{File.basename(__FILE__)} at #{Time.now.to_s}"

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
    ConcertoConfig.make_concerto_config("default_upload_type", "graphic", category: 'Content', seq_no: 10)
    ConcertoConfig.make_concerto_config("content_default_start_time", "12:00 am", value_type: "time", category: 'Content', seq_no: 20)
    ConcertoConfig.make_concerto_config("content_default_end_time", "11:59 pm", value_type: "time", category: 'Content', seq_no: 30)
    ConcertoConfig.make_concerto_config("start_date_offset", "0", value_type: "integer", category: 'Content', seq_no: 40)
    ConcertoConfig.make_concerto_config("default_content_run_time", "7", value_type: "integer", category: 'Content', seq_no: 50)
    ConcertoConfig.make_concerto_config("default_content_duration", "8", value_type: "integer", category: 'Content', seq_no: 60)
    ConcertoConfig.make_concerto_config("min_content_duration", "4", value_type: "integer", category: 'Content', seq_no: 70)
    ConcertoConfig.make_concerto_config("max_content_duration", "12", value_type: "integer", category: 'Content', seq_no: 80)

    # access
    ConcertoConfig.make_concerto_config("public_concerto", "true", value_type: "boolean", category: 'Permissions', seq_no: 99)
    ConcertoConfig.make_concerto_config("allow_registration", "true", value_type: "boolean", category: 'Permissions', seq_no: 1)
    ConcertoConfig.make_concerto_config("confirmable", "false", value_type: "boolean", category: 'Permissions', seq_no: 2)
    ConcertoConfig.make_concerto_config("allow_user_screen_creation", "false", value_type: "boolean", category: 'Permissions', seq_no: 99)
    ConcertoConfig.make_concerto_config("allow_user_feed_creation", "true", value_type: "boolean", category: 'Permissions', seq_no: 99)

    # mail
    ConcertoConfig.make_concerto_config('mailer_protocol', 'sendmail', value_type: 'select', select_values: "{'Sendmail': 'sendmail', 'SMTP': 'smtp'}", category: 'Mail', seq_no: 1)
    ConcertoConfig.make_concerto_config("mailer_from", "concerto@localhost", value_type: "string", value_default: "concerto@localhost", category: 'Mail', seq_no: 2)
    ConcertoConfig.make_concerto_config("mailer_host", concerto_hostname, value_type: "string", value_default: concerto_hostname, category: 'Mail', seq_no: 3,
      description: "This is used to construct links in the email that point back to the concerto application.")
    ConcertoConfig.make_concerto_config("smtp_address", "", value_type: "string", category: 'Mail', seq_no: 4)
    ConcertoConfig.make_concerto_config("smtp_port", "587", value_type: "integer", value_default: 587, category: 'Mail', seq_no: 5)
    ConcertoConfig.make_concerto_config("smtp_auth_type", "plain", value_type: "string", value_default: "plain", category: 'Mail', seq_no: 6)
    ConcertoConfig.make_concerto_config("smtp_username", "", value_type: "string", category: 'Mail', seq_no: 7,
      description: "If no SMTP authentication is required, this field should be blank.")
    ConcertoConfig.make_concerto_config("smtp_password", "", value_type: "string", category: 'Mail', seq_no: 8)
    ConcertoConfig.make_concerto_config("openssl_verify_mode_none", "false", value_type: "boolean", value_default: "false", category: 'Mail', seq_no: 9,
      description: "If checked, sets the OpenSSL Verify mode to none which allows SSL encryption to occur even if the host's certificate cannot be verified.  Typically checked if using self-signed certificates on your SMTP server.")

    # background processing
    ConcertoConfig.make_concerto_config("worker_heartbeat", "0", value_type: "integer", category: 'Processing', hidden: "true", can_cache: false)

    # system
    ConcertoConfig.make_concerto_config("setup_complete", "false", value_type: "boolean", value_default: "true", hidden: "true", category: 'System')
    ConcertoConfig.make_concerto_config('session_store', 'cache_store', value_type: 'select', select_values: "{'Cache Store': 'cache_store', 'Cookie Store': 'cookie_store', 'ActiveRecord Store': 'active_record_store'}", category: 'System', seq_no: 1,
      description: 'Memcached option required a running memcached installation.')
    ConcertoConfig.make_concerto_config("system_time_zone", 'Eastern Time (US & Canada)', value_type: "timezone", category: 'System')
    ConcertoConfig.make_concerto_config("config_last_updated", "0", value_type: "integer", hidden: "true", category: 'System')
    ConcertoConfig.make_concerto_config("http_proxy_settings", "", value_type: "string", category: 'System',
      description: 'http://username:password@hostname:port')
    ConcertoConfig.make_concerto_config("keep_activity_log", "90", value_type: "integer", value_default: "90", category: 'System',
      description: 'Days to keep activity log for (where 0 is forever)')
    ConcertoConfig.make_concerto_config("motd_html", "", value_type: "text", category: 'System',
      description: 'HTML to display as the \'message of the day\' on the dashboard and browse page.', seq_no: 90)
    ConcertoConfig.make_concerto_config("footer_html", "", value_type: "text", category: 'System',
      description: 'HTML to display on the footer of every page.', seq_no: 91)
    ConcertoConfig.make_concerto_config("secret_token", "", value_type: "string", value_default: "", hidden: "false", category: 'System')
  end

  Rails.logger.debug "Completed 02-concerto_config.rb at #{Time.now.to_s}"

  # 5/8/2015 - We've done something dumb in the ConcertoConfigs controller and
  # created a 3-state boolean issue where we're using NULL for false and
  # real falses are ignored and invisible - this patch fixes that
  ConcertoConfig.where("hidden IS NULL").update_all(hidden: false)

  #Set the time here instead of in application.rb to get ConcertoConfig access
  Rails.application.config.time_zone = ConcertoConfig[:system_time_zone]
  #Set Time.zone specifically, because it's too late to derive it from config.
  Time.zone = ConcertoConfig[:system_time_zone]

  if !ConcertoConfig[:http_proxy_settings].empty?
    ENV['HTTP_PROXY'] = ConcertoConfig[:http_proxy_settings]
  end

end

Rails.logger.debug "Completed #{File.basename(__FILE__)} at #{Time.now.to_s}"

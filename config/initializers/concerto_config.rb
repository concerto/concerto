#Initialize all core Concerto Config entries

if ActiveRecord::Base.connection.table_exists? 'concerto_configs'
  ConcertoConfig.make_concerto_config("default_upload_type", "graphic")
  ConcertoConfig.make_concerto_config("public_concerto", "true", :value_type => "boolean")
  ConcertoConfig.make_concerto_config("content_default_start_time", "12:00 am")
  ConcertoConfig.make_concerto_config("content_default_end_time", "11:59 pm")
  ConcertoConfig.make_concerto_config("start_date_offset", "0", :value_type => "integer")
  ConcertoConfig.make_concerto_config("default_content_run_time", "7", :value_type => "integer")
  ConcertoConfig.make_concerto_config("setup_complete", "false", :value_type => "boolean", :value_default => "true")
  ConcertoConfig.make_concerto_config("allow_registration", "true", :value_type => "boolean")
  ConcertoConfig.make_concerto_config("allow_user_screen_creation", "false", :value_type => "boolean")
  ConcertoConfig.make_concerto_config("allow_user_feed_creation", "true", :value_type => "boolean")
  ConcertoConfig.make_concerto_config("rubygem_executable", "gem")
end










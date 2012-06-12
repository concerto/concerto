#Initialize all core Concerto Config entries
#first_or_create check whether first returns nil or not; if it does return nil, create is called
ConcertoConfig.where(:key => 'default_upload_type').first_or_create(:key => "default_upload_type", :value => "graphic", :value_default => "graphic", :value_type => "string")
ConcertoConfig.where(:key => 'public_concerto').first_or_create(:key => "public_concerto", :value => "true", :value_default => "true", :value_type => "boolean")
ConcertoConfig.where(:key => 'content_default_start_time').first_or_create(:key => "content_default_start_time", :value => "12:00 am", :value_default => "12:00 am", :value_type => "string")
ConcertoConfig.where(:key => 'content_default_end_time').first_or_create(:key => "content_default_end_time", :value => "11:59 pm", :value_default => "11:59 pm", :value_type => "string")
ConcertoConfig.where(:key => 'start_date_offset').first_or_create(:key => "start_date_offset", :value => "0", :value_default => "0", :value_type => "integer")
ConcertoConfig.where(:key => 'default_content_run_time').first_or_create(:key => "default_content_run_time", :value => "7", :value_default => "7", :value_type => "integer")
ConcertoConfig.where(:key => 'setup_complete').first_or_create(:key => "setup_complete", :value => "false", :value_default => "true", :value_type => "boolean")
ConcertoConfig.where(:key => 'allow_registration').first_or_create(:key => "allow_registration", :value => "true", :value_default => "true", :value_type => "boolean")
ConcertoConfig.where(:key => 'allow_user_screen_creation').first_or_create(:key => "allow_user_screen_creation", :value => "false", :value_default => "false", :value_type => "boolean")













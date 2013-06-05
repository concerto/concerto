if ActiveRecord::Base.connection.table_exists? 'concerto_configs'
  ActionMailer::Base.delivery_method = ConcertoConfig[:mailer_protocol].to_sym
  ActionMailer::Base.default_url_options = { :host => ConcertoConfig[:mailer_host] }
  
  if ConcertoConfig[:mailer_protocol] == 'smtp'
    ActionMailer::Base.smtp_settings = {
      :address => ConcertoConfig[:smtp_address],
      :port => ConcertoConfig[:smtp_port],
      :enable_starttls_auto => true,
      :authentication => ConcertoConfig[:smtp_auth_type],
      :user_name => ConcertoConfig[:smtp_username],
      :password => ConcertoConfig[:smtp_password]
    }
  end
end
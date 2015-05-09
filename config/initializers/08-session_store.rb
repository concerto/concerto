# Be sure to restart your server when you modify this file.

Rails.logger.debug "Starting #{File.basename(__FILE__)} at #{Time.now.to_s}"

Concerto::Application.config.session_store(ConcertoConfig[:session_store].to_sym)

Rails.logger.debug "Completed #{File.basename(__FILE__)} at #{Time.now.to_s}"

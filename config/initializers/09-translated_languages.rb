Rails.logger.debug "Starting #{File.basename(__FILE__)} at #{Time.now.to_s}"

#A hash of the languages that have been fully translated and are ready for user use
#Also provide a human-readable language name
TRANSLATED_LANGUAGES = {'English' => 'en'} 

Rails.logger.debug "Completed #{File.basename(__FILE__)} at #{Time.now.to_s}"

Rails.logger.debug "Starting #{File.basename(__FILE__)} at #{Time.now.to_s}"

# An array of all the possible content types a user can upload content to.
# Plugins will want to append their classes to this list.
Concerto::Application.config.content_types = [Ticker, Graphic]

# We need to load unused content types too.
# Since Rails lazy-loads models, rails doesn't have a complete picture of
# all the Content children, only the ones that have been loaded / used.
Concerto::Application.config._unused_content_types_ = [HtmlText]

Rails.logger.debug "Completed #{File.basename(__FILE__)} at #{Time.now.to_s}"

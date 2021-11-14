Rails.logger.debug "Starting #{File.basename(__FILE__)} at #{Time.now.to_s}"

# remove any obsolete config entries
if ActiveRecord::Base.connection.data_source_exists? 'concerto_configs'
  ConcertoConfig.delete_unused_configs()
end

Rails.logger.debug "Completed #{File.basename(__FILE__)} at #{Time.now.to_s}"

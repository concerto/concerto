Rails.logger.debug "Starting 99-remove_unused_config_entries.rb at #{Time.now.to_s}"

# remove any obsolete config entries
if ActiveRecord::Base.connection.table_exists? 'concerto_configs'
  ConcertoConfig.delete_unused_configs()
end


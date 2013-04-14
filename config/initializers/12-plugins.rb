Rails.logger.debug "Starting 12-plugins.rb at #{Time.now.to_s}"

# Concerto Plugins Initializer
if ActiveRecord::Base.connection.table_exists? 'concerto_plugins'
  # First register any plugin configs.
  # This will cause ConcertoPlugin to call the ConcertoConfig
  # class for all of the enabled plugins.
  ConcertoPlugin.make_plugin_configs

  # Next run any boot-time initialization code that the
  # plugins might need.
  ConcertoPlugin.initialize_plugins
  
  # Mount all the engines at their requested mount points.
  # In the future, this may perform more strict checking to
  # make sure that the plugin is enabled and the app exists.
  Rails.application.routes.append do
    mount_points = ConcertoPlugin.get_mount_points 
    if  mount_points.is_a? Array 
      mount_points.each do |app|
        mount app[:rack_app] => "/" + app[:url_string]
        # e.g. mount ConcertoHardware::Engine => "/hardware"
      end
    end
  end
end

Rails.logger.debug "Completed 12-plugins.rb at #{Time.now.to_s}"

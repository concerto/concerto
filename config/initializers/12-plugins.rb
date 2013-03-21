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
  
  #Go over all installed engines to check if a spec matches a plugin in the concerto_plugins table and add the module name
  ConcertoPlugin.where(:module_name => nil) do |plugin|
    #We already know the name of the gem from user input, so let's get its full path in the filesystem
    gpath = Gem.loaded_specs[plugin.gem_name].full_gem_path
    #then match the path we've got to the path of an engine - which should have its Module Name (aka paydirt)
    Rails::Application::Railties.engines do |engine| 
      if engine.class.root.to_s == gpath
        #get the class name from the engine hash
        plugin.module_name = engine.class.name
        #save new metadata to the concerto_plugins table
        plugin.save
      end
    end
  end

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
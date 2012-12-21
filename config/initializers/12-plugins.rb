# Concerto Plugins Initializer

# This initializer assumes that all gems have been loaded
# and that the database is fully migrated and ActivRecord
# is connected to it.

# First enumerate plugins that are installed and enabled,
# and then run their initialization code. This will include
# installation tasks, setting up configs, and requesting
# routes.
ConcertoPlugin.initialize_plugins

# Mount all the engines at their requested mount points.
# In the future, this may perform more strict checking to
# make sure that the plugin is enabled and the app exists.
Rails.application.routes.append do
  if ConcertoPlugin.apps_to_mount.is_a? Array 
    ConcertoPlugin.apps_to_mount.each do |app|
      mount app[:rack_app] => "/" + app[:url_string], :as => app[:url_string]
      # e.g. mount ConcertoHardware::Engine => "/hardware"
    end
  end
end

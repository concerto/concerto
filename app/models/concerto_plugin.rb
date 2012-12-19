# This class is a model for the ConcertoPlugin database table,
# which manages the available and enabled plugins for Concerto.
#
# It also includes the code that allows the rest of the application
# to interface to individual plugins, including initialization tasks
# as well as controller and view hooks.
#
# This code interfaces closely with lib/concerto/plugin_library.rb,
# which can be included into engines to enable use of the Concerto
# Plugin interface.

class ConcertoPlugin < ActiveRecord::Base
  attr_accessible :enabled, :gem_name, :gem_version, :installed, :module_name, :name, :source, :source_url

  mattr_accessor :apps_to_mount

  # Method to be called exactly once at app boot
  # Will iterate over all the enabled plugins, and attempt to
  # run their initialization code. This is a hook for plugins
  # to take care of their proper installation, set up configs,
  # set up hooks, and request routing if needed.
  def self.initialize_plugins
    method_name = "initialize_plugin"
    logger.info "ConcertoPlugin: Initializing Plugins"
    ConcertoPlugin.all.each do |plugin|
      if plugin.enabled?
        if Object.const_defined?(plugin.module_name) 
          mod = plugin.module_name.constantize
          if mod.respond_to? method_name
            mod.method(method_name).call(plugin)
          else 
            logger.warn(
              "ConcertoPlugin: Plugin #{plugin.name} does not respond to " +
              method_name + ", skipping initialization.")
          end
        else
          logger.warn(
            "ConcertoPlugin: Plugin #{plugin.name} module (" +
            plugin.module_name + ") not found. Skipping initialization.")
        end
      end
    end
  end

  # Used by the plugin initializer to register its own information
  # Options hash takes the same arguments as ConcertoConfig.make_concerto_config
  # except for the plugin_id field.
  def make_plugin_config(config_key, config_value, options={})
    options[:plugin_id] = id
    ConcertoConfig.make_concerto_config(config_key, config_value, options)
  end

  # Requests that the plugin be mounted as a rack app at
  #   Rails.root/url_string
  # The plugin is responsible for setting its own engine name.
  # Should only be called by the plugin during initialization.
  def request_route(url_string, rack_app)
    self.apps_to_mount = self.apps_to_mount || []
    self.apps_to_mount << {:url_string => url_string, :rack_app => rack_app}
  end
  
  def self.get_engine(plugin_name)
    if Object.const_defined?(plugin_name) 
      mod = plugin_name.constantize
      if mod.const_defined?("Engine")
        engine = mod.const_get("Engine")
        return engine
      else
        logger.warn("ConcertoPlugin: #{plugin_name} Engine Class " +
                    plugin.module_name + " not found.")
        return false
      end
    else
      logger.warn("ConcertoPlugin: #{plugin+name} module (" +
                    plugin_name + ") not found.")
      return false
    end
  end

  # This is very inefficient, especially for multiple hooks in one view.
  # However, the API is implementation-agnostic.
  def self.render_view_hook(context, hook_name)
    result = ""
    controller_name = context.controller.controller_name
    ConcertoPlugin.all.each do |plugin|
      if plugin.enabled?
        if engine = get_engine(plugin.module_name)
          engine.get_view_hooks(controller_name, hook_name).each do |hook|
            if hook[:type] == :partial
              result += context.render :partial => hook[:hook]
            elsif hook[:type] == :text
              result += hook[:hook]
            elsif hook[:type] == :proc
              result += context.instance_eval(&hook[:hook])
            end
            result += "\n"
          end
        else
          logger.warn("ConcertoPlugin: Failed to check view hooks for "+
                      "#{plugin.name}")
        end
      end
    end
    return result.html_safe
  end

  def self.install_callbacks(controller)
    method_name = "get_controller_hooks"
    callbacks = []
    ConcertoPlugin.all.each do |plugin|
      if plugin.enabled?
        if engine = get_engine(plugin.module_name)
          if engine.respond_to? method_name
            controller_callbacks = engine.instance.method(method_name).call(controller.name)
            if controller_callbacks.is_a? Array
              callbacks += controller_callbacks
            end
          else 
            logger.warn("ConcertoPlugin: #{plugin.name} does not respond to "+
                        method_name + ", skipping callbacks.")
          end
        else
          logger.warn("ConcertoPlugin: failed to check #{plugin.name}" +
                      " for callbacks")
        end
      end
    end
    logger.info "ConcertoPlugin: Callbacks for this controller listed below:"
    logger.info callbacks.to_yaml
    callbacks.each do |callback|
      controller.set_callback(callback[:name], callback[:filter_list], callback[:block])
    end
    logger.info "Concerto_Plugin: Done with callbacks"
  end
end

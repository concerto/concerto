# This class is a model for the ConcertoPlugin database table,
# which manages the available and enabled plugins for Concerto.
#
# It also includes the code that allows the rest of the application
# to interface to individual plugins, including initialization tasks
# and controller/view hooks.
#
# This code interfaces closely with lib/concerto/plugin_info.rb,
# which gets instantiated in engines to enable use of the Concerto
# Plugin interface.

class ConcertoPlugin < ActiveRecord::Base
  attr_accessible :enabled, :gem_name, :gem_version, :installed, :source, :source_url
  validates :gem_name, :presence => true
  # TODO: use check_sources to validate the availability of the gem
  
  scope :enabled, where(:enabled => true)

  # Find the Engine's module from among the installed engines.
  def engine
    @engine ||= find_engine
  end

  def installed?
    !engine.nil?
  end

  def mod
    engine.parent
  end
 
  def module_name
    engine.nil? ? "" : engine.parent.name
  end

  def name
    gem_name.humanize
  end

  # Returns the instance of PluginInfo provided by the engine
  # Note for simplicity we're not caching this info.
  def plugin_info
    info = nil
    if installed? and engine.respond_to? "plugin_info"
      info = engine.plugin_info(Concerto::PluginInfo)
    end
    info
  end

  # Method to be called exactly once at app boot.
  # Will iterate over all the enabled plugins, and run any
  # initialization code they have specified.
  def self.initialize_plugins
    method_name = "initialize_plugin"
    ConcertoPlugin.enabled.each do |plugin|
      if info = plugin.plugin_info
        if info.init_block.is_a? Proc
          info.init_block.call
        end
      end
    end
  end

  # Uses ConcertoConfig to initialize any configuration objects
  # requested by enabled plugins. Called by initializer at boot.
  def self.make_plugin_configs
    configs = []
    ConcertoPlugin.enabled.each do |plugin|
      if info = plugin.plugin_info
        (info.configs || []).each do |c|
          c[:options][:plugin_id] = plugin.id
          ConcertoConfig.make_concerto_config(
            c[:config_key], c[:config_value], c[:options]
          )
        end
      end
    end
  end

  # Finds all the requested engine mount points and associated
  # info, and returns the corressponding array of hashes.
  def self.get_mount_points
    mount_points = []
    ConcertoPlugin.enabled.each do |plugin|
      if info = plugin.plugin_info
        if info.mount_points.is_a? Array
          mount_points += info.mount_points
        end
      end
    end
    mount_points
  end

  # Given the view's rendering context, renders all the requests for
  # the given hook from enabled plugins, and returns the resulting
  # string.
  # This is very inefficient, especially for multiple hooks in one view.
  # However, the API is implementation-agnostic.
  def self.render_view_hook(context, hook_name)
    result = ""
    controller_name = context.controller.controller_name
    ConcertoPlugin.enabled.each do |plugin|
      if info = plugin.plugin_info
        info.get_view_hooks(controller_name, hook_name).each do |hook|
          # Make the authorization rules from the plugin available
          context.controller.switch_to_plugin_ability(plugin.mod)
          if hook[:type] == :partial
            result += context.render :partial => hook[:hook]
          elsif hook[:type] == :text
            result += hook[:hook]
          elsif hook[:type] == :proc
            result += context.instance_eval(&hook[:hook])
          end
          # Cleanup
          context.controller.switch_to_main_app_ability
          result += "\n"
        end
      else
        logger.warn("ConcertoPlugin: Failed to check view hooks for "+
                    "#{plugin.name}")
      end
    end
    return result.html_safe
  end

  # Installs all the code requested by enabled plugins for hooks
  # in the given controller as callbacks which can then be triggered
  # by code in the controller.
  def self.install_callbacks(controller)
    method_name = "get_controller_hooks"
    callbacks = []
    ConcertoPlugin.enabled.each do |plugin|
      if info = plugin.plugin_info
        controller_callbacks = info.get_controller_hooks(controller.name)
        if controller_callbacks.is_a? Array
          callbacks += controller_callbacks
        end
      else
        logger.warn("ConcertoPlugin: failed to check #{plugin.name}" +
                    " for callbacks")
      end
    end
    callbacks.each do |callback|
      controller.set_callback(callback[:name], callback[:filter_list], callback[:block])
    end
  end

private

  #custom validation for plugin URLs
  def check_sources
    case self.source
      when "rubygems"
        require 'net/http'
        r = Net::HTTP.get_response(URI.parse("http://rubygems.org/gems/#{self.gem_name}"))
        Net::HTTPSuccess === r ? (return true) : (return false)        
      when "git"
        require 'command_check'
        if command?('git')
          git_ls = system("git ls-remote #{self.source.url}")
          #git ls returns 0 on success, 128 on failure
          git_ls == 0 ? (return true) : (return false) 
        end
      when "path"
        #get the directory of the provided gemfile
        plugin_path = File.dirname(self.source_url)
        #user Dir to see if a gemfile exists in that directory
        return !Dir.glob("#{plugin_path}/*.gemspec").empty?
    end
  end

  # Find an engine by using the gem name to find an installed
  # gem, and matching it against the list of available engines.
  # Returns nil if no engine is not found.
  def find_engine
    # We already know the name of the gem from user input
    if Gem.loaded_specs.has_key? gem_name
      # Let's get the gem's full path in the filesystem
      gpath = Gem.loaded_specs[gem_name].full_gem_path
      # Then match the path we've got to the path of an engine - 
      #    which should have its Module Name (aka paydirt)
      Rails::Application::Railties.engines do |engine| 
        if engine.class.root.to_s == gpath
          # Get the class name from the engine hash
          result = engine.class.name
          break
        end
      end
    else # Gem not loaded
      result = nil
    end
    result
  end
end

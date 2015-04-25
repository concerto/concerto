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
  include ActiveModel::ForbiddenAttributesProtection
  include PublicActivity::Common if defined? PublicActivity::Common

  validates :gem_name, presence: true, uniqueness: true
  validate :check_sources, on: :create

  scope :enabled, -> { where(enabled: true) }

  def self.concerto_addons
    repositories = Octokit.repos 'concerto-addons'
    addons = Array.new
    repositories.each do |r|
      addons << [r.name.titleize, r.name]
    end
    return addons
  end

  ADDONS = self.concerto_addons

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
  def self.render_view_hook(context, hook_name, local_options = nil)
    result = ""
    controller_name = context.controller.controller_name
    ConcertoPlugin.enabled.each do |plugin|
      if info = plugin.plugin_info
        info.get_view_hooks(controller_name, hook_name).each do |hook|
          # Make the authorization rules from the plugin available
          context.controller.switch_to_plugin_ability(plugin.mod)
          if hook[:type] == :partial
            result += context.render partial: hook[:hook], locals: local_options
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
        logger.debug("ConcertoPlugin: Failed to check view hooks for #{plugin.name}")
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
        logger.warn("ConcertoPlugin: failed to check #{plugin.name} for callbacks")
      end
    end if ActiveRecord::Base.connection.table_exists? 'concerto_plugins'

    callbacks.each do |callback|
      controller.set_callback(callback[:name], callback[:filter_list], callback[:block])
    end
  end

  # Extends models by including modules (preferably ActiveSupport::Concern)
  def self.extend_models
    ConcertoPlugin.enabled.each do |plugin|
      info = plugin.plugin_info
      next if info.nil? || info.model_extensions.nil?

      info.model_extensions.each do |model, extensions|
        model.class_eval do
          extensions.each do |extension|
            include extension
          end
        end
      end
    end
  end

  def self.install_cron_jobs(clockwork)
    ConcertoPlugin.enabled.each do |plugin|
      info = plugin.plugin_info
      next if info.nil? || info.cron_jobs.nil?

      info.cron_jobs.each do |job|
        clockwork.every(job[:period], job[:name], job[:options]) do
          job[:block].call if job[:block]
        end
      end
    end
  end

  def self.add_header_tags(context)
    result = ''
    ConcertoPlugin.enabled.each do |plugin|
      begin
        info = plugin.plugin_info
        if info && info.header_tags
          info.header_tags.each do |hook|
            hook_content = case hook[:type]
                              when :partial
                               context.render partial: hook[:hook]
                             when :text
                               hook[:hook]
                             when :proc
                               context.instance_eval(&hook[:hook])
                             else
                               logger.warn("ConcertoPlugin: failed to add header tags for #{plugin.name}: Unsupported hook type #{hook[:type]}")
                               nil
                           end
            if hook_content
              result += hook_content
              result += "\n"
            end
          end
        end
      rescue Exception => e
        logger.warn("ConcertoPlugin: failed to add header tags for #{plugin.name}: #{e}\n#{e.backtrace.join("\n")}")
      end
    end
    return result.html_safe

  end

private

  # custom validation for plugin URLs
  def check_sources
    case self.source
      when "rubygems"
        return false if self.gem_name.empty?
        #runs the gem search command and looks for non-empty input to see if the gem exists in some source
        (`gem search #{self.gem_name}`.chomp.empty?) ? errors.add(:gem_name, "#{self.gem_name} #{I18n.t(:gem_not_found)}") : (return true)
      when "git"
        if self.source_url.empty?
          errors.add(:source_url, I18n.t(:cant_be_blank))
          return false
        end
        require 'command_check'
        if command?('git')
          git_ls = system("git", "ls-remote", self.source_url)
          if git_ls != true
            errors.add(:source_url, "#{self.source_url} #{I18n.t(:valid_git)}")
          end
        end
      when "path"
        if self.source_url.empty?
          errors.add(:source_url, I18n.t(:cant_be_blank))
          return false
        end
        # Use Dir to see if a gemfile exists in that directory, and protect
        # it with File.directory? to keep out wildcards (resource hog).
        # Make the two cases somewhat indistinguishable to avoid revealing
        # irrelevant system properties.
        if (!File.directory? self.source_url or
            Dir.glob("#{self.source_url}/*.gemspec").empty?)
          errors.add(:source_url, "#{I18n.t(:gemspec_not_found)} #{self.source_url}")
        end
    end
  end

  # Find an engine by using the gem name to find an installed
  # gem, and matching it against the list of available engines.
  # Returns nil if no engine is not found.
  def find_engine
    result = nil
    # We already know the name of the gem from user input
    if Gem.loaded_specs.has_key? gem_name
      # Let's get the gem's basename in the filesystem
      gem_basename = Pathname(Gem.loaded_specs[gem_name].full_gem_path).basename
      # Then match the name we've got to the name of an engine -
      #    which should have its Module Name (aka paydirt)
      ::Rails::Engine.subclasses.map(&:instance).each do |engine|
        if engine.class.root.basename == gem_basename
          # Get the class name from the engine hash
          result = engine.class
          break
        end
      end
    end
    result
  end
end

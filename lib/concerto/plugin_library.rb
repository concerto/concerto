# The PluginLibrary class is not used directly in Concerto, but
# is provided to plugins to include into their Engines for 
#
# The methods provide below provide a two-way API: a set of
# methods to be called within the Engine class to configure
# callbacks and the like; and a set of methods to be called
# by the ConcertoPlugin model when interfacing to the rest of
# the Concerto application.

# TODO: pull in plugin initialization stuff (config items, route)

module Concerto
  module PluginLibrary
    module ClassMethods
      attr_accessor :controller_hooks 
      attr_accessor :view_hooks

      # TODO: test with multiple callbacks
      def add_controller_hook(controller_name, name, filter_list, &block)
        @controller_hooks ||= []
        @controller_hooks << { 
          :controller_name => controller_name, 
          :name => name, 
          :filter_list => filter_list,
          :block => block
        }
      end

      def get_controller_hooks(controller_name)
        return @controller_hooks.select do |h| 
          h[:controller_name] == controller_name
        end
      end

      def add_view_hook(controller_name, hook_sym, options={})
        @view_hooks ||= []
        if options.has_key? :partial
          mytype=:partial
          myhook=options[:partial]
        elsif options.has_key? :text
          mytype=:text
          myhook=options[:text]
        elsif options.has_key? :proc
          mytype=:proc
          myhook=options[:proc]
        elsif block_given?
          mytype = :proc
          myhook = Proc.new # takes the value of the passed block
        elsif not hook
          raise "error: add_view_hook missing a block, partial, or text!"
        end

        @view_hooks << {
          :controller_name => controller_name, 
          :sym => hook_sym, 
          :type => mytype,
          :hook => myhook
        }
      end

      def get_view_hooks(controller_name, hook_sym)
        hooks = []
        @view_hooks.each do |hook|
          if hook[:controller_name] = controller_name
            if hook[:sym] == hook_sym
              hooks << hook
            end
          end
        end
        return hooks
      end # get_view_hooks

    end # ClassMethods
  end # PluginLibrary
end # Concerto

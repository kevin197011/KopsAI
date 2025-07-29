# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

module KopsAI
  module Core
    # Main agent class that manages all plugins
    class Agent
      def initialize
        @plugins = {}
        @logger = KopsAI.logger
        load_plugins
      end

      # Register a plugin
      def register_plugin(plugin)
        @plugins[plugin.name] = plugin
        @logger.info('Plugin registered', plugin: plugin.name, version: plugin.version)
      end

      # Get a plugin by name
      def plugin(name)
        @plugins[name.to_s]
      end

      # List all available plugins
      def plugins
        @plugins.values
      end

      # Execute a plugin
      def execute_plugin(name, *args)
        plugin = plugin(name)
        raise Error, "Plugin '#{name}' not found" unless plugin

        raise Error, "Plugin '#{name}' is not available" unless plugin.available?

        @logger.info('Executing plugin', plugin: name, args: args)
        result = plugin.execute(*args)
        @logger.info('Plugin execution completed', plugin: name)
        result
      rescue StandardError => e
        @logger.error('Plugin execution failed', error: e, plugin: name)
        raise
      end

      # Get plugin info
      def plugin_info(name)
        plugin = plugin(name)
        return nil unless plugin

        plugin.info
      end

      # List all plugins with their info
      def list_plugins
        @plugins.transform_values(&:info)
      end

      private

      def load_plugins
        register_plugin(Plugins::SystemCheck.new)
        register_plugin(Plugins::SSHRemote.new)
        register_plugin(Plugins::K8sAgent.new)
        register_plugin(Plugins::PrometheusAgent.new)
        register_plugin(Plugins::JenkinsAgent.new)
        register_plugin(Plugins::LogAgent.new)
        register_plugin(Plugins::GPTSupport.new)
        register_plugin(Plugins::Notifier.new)
      end
    end
  end
end

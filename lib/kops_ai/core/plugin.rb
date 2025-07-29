# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

module KopsAI
  module Core
    # Base plugin class for KopsAI
    class Plugin
      attr_reader :name, :description, :version

      def initialize(name:, description: '', version: '1.0.0')
        @name = name
        @description = description
        @version = version
      end

      # Execute the plugin
      def execute(*args)
        raise NotImplementedError, "#{self.class} must implement #execute"
      end

      # Check if plugin is available
      def available?
        true
      end

      # Get plugin info
      def info
        {
          name: @name,
          description: @description,
          version: @version,
          available: available?
        }
      end

      # Validate plugin configuration
      def validate_config
        true
      end

      protected

      def logger
        KopsAI::Core::Logger.instance
      end

      def config
        KopsAI.config
      end
    end
  end
end

# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

require 'yaml'
require 'dry-struct'
require 'dry-types'

module KopsAI
  module Core
    module Types
      include Dry.Types()
    end

    # Configuration structure for KopsAI
    class Config < Dry::Struct
      attribute :log_level, Types::String.default('info')
      attribute :service_name, Types::String.default('kops-ai')
      attribute :openai_api_key, Types::String.optional
      attribute :openai_model, Types::String.default('gpt-4')
      attribute :prometheus_url, Types::String.optional
      attribute :jenkins_url, Types::String.optional
      attribute :jenkins_username, Types::String.optional
      attribute :jenkins_token, Types::String.optional
      attribute :k8s_config_path, Types::String.optional
      attribute :notification_webhook, Types::String.optional
      attribute :ssh_timeout, Types::Integer.default(30)
      attribute :ssh_retries, Types::Integer.default(3)
    end

    # Configuration manager
    class ConfigManager
      include Singleton

      def initialize
        @config = load_config
      end

      def get(key)
        @config.public_send(key)
      end

      def set(key, value)
        @config = @config.new(key => value)
      end

      def reload
        @config = load_config
      end

      private

      def load_config
        config_data = default_config.merge(load_from_file).merge(load_from_env)
        Config.new(config_data)
      end

      def default_config
        {
          log_level: 'info',
          service_name: 'kops-ai',
          openai_model: 'gpt-4',
          ssh_timeout: 30,
          ssh_retries: 3
        }
      end

      def load_from_file
        config_file = ENV.fetch('KOPS_CONFIG', 'config/kops.yml')
        return {} unless File.exist?(config_file)

        YAML.load_file(config_file) || {}
      rescue StandardError => e
        KopsAI.logger.warn("Failed to load config file: #{e.message}")
        {}
      end

      def load_from_env
        {
          log_level: ENV.fetch('LOG_LEVEL', nil),
          service_name: ENV.fetch('SERVICE_NAME', nil),
          openai_api_key: ENV.fetch('OPENAI_API_KEY', nil),
          openai_model: ENV.fetch('OPENAI_MODEL', nil),
          prometheus_url: ENV.fetch('PROMETHEUS_URL', nil),
          jenkins_url: ENV.fetch('JENKINS_URL', nil),
          jenkins_username: ENV.fetch('JENKINS_USERNAME', nil),
          jenkins_token: ENV.fetch('JENKINS_TOKEN', nil),
          k8s_config_path: ENV.fetch('K8S_CONFIG_PATH', nil),
          notification_webhook: ENV.fetch('NOTIFICATION_WEBHOOK', nil),
          ssh_timeout: ENV['SSH_TIMEOUT']&.to_i,
          ssh_retries: ENV['SSH_RETRIES']&.to_i
        }.compact
      end
    end
  end
end

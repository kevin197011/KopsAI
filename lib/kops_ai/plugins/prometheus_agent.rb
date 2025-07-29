# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

module KopsAI
  module Plugins
    # Prometheus metrics query plugin
    class PrometheusAgent < Core::Plugin
      def initialize
        super(
          name: 'prometheus_agent',
          description: 'Query Prometheus metrics and generate reports',
          version: '1.0.0'
        )
      end

      def execute(action, **options)
        case action.to_s
        when 'query'
          query_metrics(options[:query], options[:start], options[:end])
        when 'alerts'
          get_alerts
        when 'targets'
          get_targets
        when 'rules'
          get_rules
        else
          raise ArgumentError, "Unknown action: #{action}"
        end
      end

      def available?
        return false unless prometheus_url

        # Test connection
        test_connection
        true
      rescue StandardError
        false
      end

      private

      def prometheus_url
        config.get(:prometheus_url) || ENV.fetch('PROMETHEUS_URL', nil)
      end

      def test_connection
        require 'httpx'
        response = HTTPX.get("#{prometheus_url}/api/v1/query?query=up")
        response.raise_for_status
      rescue StandardError => e
        logger.error('Prometheus connection test failed', error: e.message)
        raise
      end

      def query_metrics(query, start_time = nil, end_time = nil)
        require 'httpx'

        params = { query: query }
        params[:start] = start_time if start_time
        params[:end] = end_time if end_time

        response = HTTPX.get("#{prometheus_url}/api/v1/query", params: params)
        response.raise_for_status

        data = JSON.parse(response.body.to_s)
        {
          query: query,
          result: data['data']['result'],
          status: data['status']
        }
      rescue StandardError => e
        logger.error('Prometheus query failed', error: e.message, query: query)
        { error: e.message }
      end

      def get_alerts
        require 'httpx'

        response = HTTPX.get("#{prometheus_url}/api/v1/alerts")
        response.raise_for_status

        data = JSON.parse(response.body.to_s)
        {
          alerts: data['data']['alerts'],
          status: data['status']
        }
      rescue StandardError => e
        logger.error('Failed to get Prometheus alerts', error: e.message)
        { error: e.message }
      end

      def get_targets
        require 'httpx'

        response = HTTPX.get("#{prometheus_url}/api/v1/targets")
        response.raise_for_status

        data = JSON.parse(response.body.to_s)
        {
          targets: data['data']['activeTargets'],
          status: data['status']
        }
      rescue StandardError => e
        logger.error('Failed to get Prometheus targets', error: e.message)
        { error: e.message }
      end

      def get_rules
        require 'httpx'

        response = HTTPX.get("#{prometheus_url}/api/v1/rules")
        response.raise_for_status

        data = JSON.parse(response.body.to_s)
        {
          rules: data['data']['groups'],
          status: data['status']
        }
      rescue StandardError => e
        logger.error('Failed to get Prometheus rules', error: e.message)
        { error: e.message }
      end
    end
  end
end

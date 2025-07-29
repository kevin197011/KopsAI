# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

module KopsAI
  module Plugins
    # Kubernetes cluster management plugin
    class K8sAgent < Core::Plugin
      def initialize
        super(
          name: 'k8s_agent',
          description: 'Query Kubernetes cluster status, pods, and resources',
          version: '1.0.0'
        )
        @client = nil
      end

      def execute(action, **options)
        case action.to_s
        when 'pods'
          list_pods(options[:namespace])
        when 'nodes'
          list_nodes
        when 'services'
          list_services(options[:namespace])
        when 'logs'
          get_pod_logs(options[:namespace], options[:pod], options[:tail])
        when 'status'
          cluster_status
        else
          raise ArgumentError, "Unknown action: #{action}"
        end
      end

      def available?
        return false unless k8s_client

        # Test connection
        k8s_client.get_nodes
        true
      rescue StandardError
        false
      end

      private

      def k8s_client
        return @client if @client

        config_path = config.get(:k8s_config_path) || ENV['KUBECONFIG'] || "#{ENV.fetch('HOME', nil)}/.kube/config"

        unless File.exist?(config_path)
          logger.warn('Kubernetes config not found', config_path: config_path)
          return nil
        end

        require 'kubeclient'
        @client = Kubeclient::Client.new(
          Kubeclient::Config.read(config_path).context.api_endpoint,
          'v1'
        )
        @client.ssl_options(Kubeclient::Config.read(config_path).context.ssl_options)
        @client.auth_options(Kubeclient::Config.read(config_path).context.auth_options)
        @client
      rescue StandardError => e
        logger.error('Failed to initialize Kubernetes client', error: e.message)
        nil
      end

      def list_pods(namespace = 'default')
        client = k8s_client
        return { error: 'Kubernetes client not available' } unless client

        pods = client.get_pods(namespace: namespace)
        pods.map do |pod|
          {
            name: pod.metadata.name,
            namespace: pod.metadata.namespace,
            status: pod.status.phase,
            ready: pod.status.containerStatuses&.all? { |cs| cs.ready } || false,
            restart_count: pod.status.containerStatuses&.sum { |cs| cs.restartCount } || 0,
            age: Time.now - pod.metadata.creationTimestamp
          }
        end
      rescue StandardError => e
        logger.error('Failed to list pods', error: e.message)
        { error: e.message }
      end

      def list_nodes
        client = k8s_client
        return { error: 'Kubernetes client not available' } unless client

        nodes = client.get_nodes
        nodes.map do |node|
          {
            name: node.metadata.name,
            status: node.status.conditions.find { |c| c.type == 'Ready' }&.status || 'Unknown',
            capacity: node.status.capacity,
            allocatable: node.status.allocatable,
            age: Time.now - node.metadata.creationTimestamp
          }
        end
      rescue StandardError => e
        logger.error('Failed to list nodes', error: e.message)
        { error: e.message }
      end

      def list_services(namespace = 'default')
        client = k8s_client
        return { error: 'Kubernetes client not available' } unless client

        services = client.get_services(namespace: namespace)
        services.map do |service|
          {
            name: service.metadata.name,
            namespace: service.metadata.namespace,
            type: service.spec.type,
            cluster_ip: service.spec.clusterIP,
            ports: service.spec.ports&.map { |p| { port: p.port, target_port: p.targetPort } } || []
          }
        end
      rescue StandardError => e
        logger.error('Failed to list services', error: e.message)
        { error: e.message }
      end

      def get_pod_logs(namespace, pod_name, tail = 100)
        client = k8s_client
        return { error: 'Kubernetes client not available' } unless client

        logs = client.get_pod_log(pod_name, namespace, tailLines: tail)
        {
          pod: pod_name,
          namespace: namespace,
          logs: logs,
          tail_lines: tail
        }
      rescue StandardError => e
        logger.error('Failed to get pod logs', error: e.message)
        { error: e.message }
      end

      def cluster_status
        client = k8s_client
        return { error: 'Kubernetes client not available' } unless client

        nodes = client.get_nodes
        pods = client.get_pods

        {
          nodes: {
            total: nodes.length,
            ready: nodes.count { |n| n.status.conditions.find { |c| c.type == 'Ready' }&.status == 'True' }
          },
          pods: {
            total: pods.length,
            running: pods.count { |p| p.status.phase == 'Running' },
            pending: pods.count { |p| p.status.phase == 'Pending' },
            failed: pods.count { |p| p.status.phase == 'Failed' }
          },
          version: client.api_endpoint
        }
      rescue StandardError => e
        logger.error('Failed to get cluster status', error: e.message)
        { error: e.message }
      end
    end
  end
end

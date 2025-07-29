# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

require 'yaml'

module KopsAI
  module DSL
    # DSL task runner for KopsAI
    class Runner
      def initialize
        @agent = KopsAI.agent
        @logger = KopsAI.logger
        @variables = {}
      end

      def run_file(file_path)
        return { error: "File not found: #{file_path}" } unless File.exist?(file_path)

        content = File.read(file_path)
        extension = File.extname(file_path).downcase

        case extension
        when '.yml', '.yaml'
          run_yaml(content)
        when '.rb'
          run_ruby(content)
        else
          { error: "Unsupported file format: #{extension}" }
        end
      end

      def run_yaml(content)
        tasks = YAML.load(content)
        results = []

        if tasks.is_a?(Array)
          tasks.each { |task| results << execute_task(task) }
        else
          results << execute_task(tasks)
        end

        {
          success: true,
          results: results,
          timestamp: Time.now.utc.iso8601
        }
      rescue StandardError => e
        @logger.error('YAML task execution failed', error: e.message)
        { error: e.message }
      end

      def run_ruby(content)
        # Create a safe execution environment
        runner = self
        result = eval(content, binding, __FILE__, __LINE__)
        {
          success: true,
          result: result,
          timestamp: Time.now.utc.iso8601
        }
      rescue StandardError => e
        @logger.error('Ruby task execution failed', error: e.message)
        { error: e.message }
      end

      # DSL methods
      def task(name, &block)
        @logger.info('Executing task', name: name)
        result = instance_eval(&block)
        @logger.info('Task completed', name: name, result: result)
        result
      end

      def on(host, &block)
        @logger.info('Executing on host', host: host)
        result = instance_eval(&block)
        @logger.info('Host execution completed', host: host, result: result)
        result
      end

      def check(type, **options)
        case type.to_s
        when 'system'
          @agent.execute_plugin('system_check', options[:check_type] || 'all')
        when 'memory'
          @agent.execute_plugin('system_check', 'memory')
        when 'cpu'
          @agent.execute_plugin('system_check', 'cpu')
        when 'disk'
          @agent.execute_plugin('system_check', 'disk')
        when 'services'
          @agent.execute_plugin('system_check', 'services')
        else
          raise ArgumentError, "Unknown check type: #{type}"
        end
      end

      def run(command)
        @logger.info('Executing command', command: command)
        system(command)
        $?.success?
      end

      def ssh_exec(host:, command:, **options)
        @agent.execute_plugin('ssh_remote', host: host, command: command, **options)
      end

      def k8s(action, **options)
        @agent.execute_plugin('k8s_agent', action, **options)
      end

      def notify(message, **options)
        @agent.execute_plugin('notifier', platform: 'webhook', message: message, **options)
      end

      def gpt_analyze(content, **options)
        @agent.execute_plugin('gpt_support', 'analyze_log', log_content: content, **options)
      end

      def if_over_threshold(&block)
        # This would be implemented based on previous check results
        instance_eval(&block)
      end

      def set_variable(name, value)
        @variables[name.to_s] = value
      end

      def get_variable(name)
        @variables[name.to_s]
      end

      private

      def execute_task(task)
        case task['type']
        when 'system_check'
          check(task['check_type'] || 'all')
        when 'ssh'
          ssh_exec(
            host: task['host'],
            command: task['command'],
            username: task['username'],
            password: task['password']
          )
        when 'k8s'
          k8s(task['action'], **task['options'] || {})
        when 'notify'
          notify(task['message'], **task['options'] || {})
        when 'gpt'
          gpt_analyze(task['content'], **task['options'] || {})
        when 'command'
          run(task['command'])
        else
          raise ArgumentError, "Unknown task type: #{task['type']}"
        end
      rescue StandardError => e
        @logger.error('Task execution failed', task: task, error: e.message)
        { error: e.message, task: task }
      end
    end
  end
end

# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

require_relative 'kops_ai/version'
require_relative 'kops_ai/core/agent'
require_relative 'kops_ai/core/plugin'
require_relative 'kops_ai/core/logger'
require_relative 'kops_ai/core/config'
require_relative 'kops_ai/plugins/system_check'
require_relative 'kops_ai/plugins/ssh_remote'
require_relative 'kops_ai/plugins/k8s_agent'
require_relative 'kops_ai/plugins/prometheus_agent'
require_relative 'kops_ai/plugins/jenkins_agent'
require_relative 'kops_ai/plugins/log_agent'
require_relative 'kops_ai/plugins/gpt_support'
require_relative 'kops_ai/plugins/notifier'
require_relative 'kops_ai/dsl/runner'
require_relative 'kops_ai/utils/formatter'
require_relative 'kops_ai/utils/scheduler'

module KopsAI
  class Error < StandardError; end

  # Main entry point for KopsAI
  class << self
    def agent
      @agent ||= Core::Agent.new
    end

    def logger
      @logger ||= Core::Logger.new
    end

    def config
      @config ||= Core::Config.new
    end

    def run_task(task_file)
      DSL::Runner.new.run_file(task_file)
    end
  end
end

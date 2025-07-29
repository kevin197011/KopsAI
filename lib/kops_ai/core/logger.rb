# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

require 'json'
require 'time'
require 'singleton'
require 'securerandom'

module KopsAI
  module Core
    # Structured logger for KopsAI
    class Logger
      include Singleton

      LEVELS = %w[debug info warn error fatal].freeze

      def initialize
        @level = ENV.fetch('LOG_LEVEL', 'info').downcase.to_sym
        @service_name = ENV.fetch('SERVICE_NAME', 'kops-ai')
        @trace_id = Thread.current[:trace_id]
        setup_logger
      end

      def info(message, **context)
        log(:info, message, **context)
      end

      def error(message, error: nil, **context)
        context[:error] = error_details(error) if error
        log(:error, message, **context)
      end

      def warn(message, **context)
        log(:warn, message, **context)
      end

      def debug(message, **context)
        log(:debug, message, **context)
      end

      def fatal(message, **context)
        log(:fatal, message, **context)
      end

      def set_trace_id(trace_id)
        Thread.current[:trace_id] = trace_id
        @trace_id = trace_id
      end

      def clear_trace_id
        Thread.current[:trace_id] = nil
        @trace_id = nil
      end

      private

      def setup_logger
        require 'logger'
        @logger = ::Logger.new($stdout)
        @logger.level = log_level
        @logger.formatter = method(:format_log)
      end

      def log(level, message, **context)
        return unless should_log?(level)

        log_data = {
          timestamp: Time.now.utc.iso8601,
          level: level.to_s.upcase,
          service: @service_name,
          message: message,
          trace_id: @trace_id || generate_trace_id
        }.merge(context)

        @logger.send(level, log_data.to_json)
      end

      def format_log(_severity, _datetime, _progname, msg)
        "#{msg}\n"
      end

      def error_details(error)
        {
          class: error.class.name,
          message: error.message,
          backtrace: error.backtrace&.first(10)
        }
      end

      def log_level
        case @level
        when :debug then ::Logger::DEBUG
        when :info then ::Logger::INFO
        when :warn then ::Logger::WARN
        when :error then ::Logger::ERROR
        when :fatal then ::Logger::FATAL
        else ::Logger::INFO
        end
      end

      def should_log?(level)
        LEVELS.index(level.to_s) >= LEVELS.index(@level.to_s)
      end

      def generate_trace_id
        SecureRandom.hex(8)
      end
    end
  end
end

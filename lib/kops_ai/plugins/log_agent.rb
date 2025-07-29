# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

module KopsAI
  module Plugins
    # Log analysis and processing plugin
    class LogAgent < Core::Plugin
      def initialize
        super(
          name: 'log_agent',
          description: 'Analyze logs and extract insights',
          version: '1.0.0'
        )
      end

      def execute(action, **options)
        case action.to_s
        when 'analyze'
          analyze_logs(options[:log_file], options[:patterns])
        when 'search'
          search_logs(options[:log_file], options[:query], options[:lines])
        when 'extract_errors'
          extract_errors(options[:log_file], options[:hours])
        when 'summary'
          generate_summary(options[:log_file], options[:hours])
        else
          raise ArgumentError, "Unknown action: #{action}"
        end
      end

      private

      def analyze_logs(log_file, patterns = nil)
        return { error: "Log file not found: #{log_file}" } unless File.exist?(log_file)

        patterns ||= default_patterns
        log_content = File.read(log_file)
        analysis = {}

        patterns.each do |name, pattern|
          matches = log_content.scan(pattern)
          analysis[name] = {
            count: matches.length,
            matches: matches.first(10) # Limit to first 10 matches
          }
        end

        {
          file: log_file,
          total_lines: log_content.lines.count,
          analysis: analysis,
          timestamp: Time.now.utc.iso8601
        }
      rescue StandardError => e
        logger.error('Log analysis failed', error: e.message, file: log_file)
        { error: e.message }
      end

      def search_logs(log_file, query, lines = 100)
        return { error: "Log file not found: #{log_file}" } unless File.exist?(log_file)

        log_content = File.readlines(log_file)
        matching_lines = []

        log_content.reverse_each do |line|
          break if matching_lines.length >= lines

          matching_lines.unshift(line) if line.include?(query)
        end

        {
          file: log_file,
          query: query,
          matches: matching_lines.length,
          lines: matching_lines
        }
      rescue StandardError => e
        logger.error('Log search failed', error: e.message, file: log_file)
        { error: e.message }
      end

      def extract_errors(log_file, hours = 24)
        return { error: "Log file not found: #{log_file}" } unless File.exist?(log_file)

        cutoff_time = Time.now - (hours * 3600)
        error_patterns = [
          /ERROR/i,
          /FATAL/i,
          /CRITICAL/i,
          /Exception/i,
          /failed/i,
          /timeout/i
        ]

        errors = []
        File.readlines(log_file).each do |line|
          next unless line.match?(Regexp.union(error_patterns))

          # Try to extract timestamp
          timestamp = extract_timestamp(line)
          next if timestamp && timestamp < cutoff_time

          errors << {
            line: line.strip,
            timestamp: timestamp,
            level: determine_error_level(line)
          }
        end

        {
          file: log_file,
          hours: hours,
          total_errors: errors.length,
          errors: errors.last(100) # Limit to last 100 errors
        }
      rescue StandardError => e
        logger.error('Error extraction failed', error: e.message, file: log_file)
        { error: e.message }
      end

      def generate_summary(log_file, hours = 24)
        return { error: "Log file not found: #{log_file}" } unless File.exist?(log_file)

        cutoff_time = Time.now - (hours * 3600)
        summary = {
          total_lines: 0,
          error_count: 0,
          warning_count: 0,
          info_count: 0,
          unique_errors: Set.new,
          hourly_distribution: Hash.new(0)
        }

        File.readlines(log_file).each do |line|
          timestamp = extract_timestamp(line)
          next if timestamp && timestamp < cutoff_time

          summary[:total_lines] += 1

          case line
          when /ERROR|FATAL|CRITICAL/i
            summary[:error_count] += 1
            summary[:unique_errors].add(line.strip)
          when /WARN/i
            summary[:warning_count] += 1
          when /INFO/i
            summary[:info_count] += 1
          end

          if timestamp
            hour = timestamp.strftime('%Y-%m-%d %H:00')
            summary[:hourly_distribution][hour] += 1
          end
        end

        {
          file: log_file,
          hours: hours,
          summary: {
            total_lines: summary[:total_lines],
            error_count: summary[:error_count],
            warning_count: summary[:warning_count],
            info_count: summary[:info_count],
            unique_errors: summary[:unique_errors].length,
            hourly_distribution: summary[:hourly_distribution]
          }
        }
      rescue StandardError => e
        logger.error('Summary generation failed', error: e.message, file: log_file)
        { error: e.message }
      end

      def default_patterns
        {
          errors: /ERROR|FATAL|CRITICAL/i,
          warnings: /WARN/i,
          info: /INFO/i,
          exceptions: /Exception|Error/i,
          timeouts: /timeout|TIMEOUT/i,
          connections: /connection|CONNECTION/i,
          requests: /request|REQUEST/i
        }
      end

      def extract_timestamp(line)
        # Common timestamp patterns
        patterns = [
          /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/,
          %r{\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}},
          /\w{3} \d{2} \d{2}:\d{2}:\d{2}/
        ]

        patterns.each do |pattern|
          next unless match = line.match(pattern)

          begin
            return Time.parse(match[0])
          rescue ArgumentError
            next
          end
        end

        nil
      end

      def determine_error_level(line)
        case line
        when /FATAL|CRITICAL/i
          'fatal'
        when /ERROR/i
          'error'
        when /WARN/i
          'warning'
        when /INFO/i
          'info'
        else
          'unknown'
        end
      end
    end
  end
end

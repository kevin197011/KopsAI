# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

require 'colorize'
require 'tty-table'

module KopsAI
  module Utils
    # Output formatting utilities
    class Formatter
      def self.format_system_check(result)
        return "❌ System check failed: #{result[:error]}" if result[:error]

        output = []
        output << '🖥️  System Status Report'
        output << ('=' * 50)

        if result[:cpu]
          cpu = result[:cpu]
          status = cpu[:usage_percent] > 80 ? '⚠️' : '✅'
          output << "#{status} CPU Usage: #{cpu[:usage_percent]}% (#{cpu[:cores]} cores)"
        end

        if result[:memory]
          mem = result[:memory]
          status = mem[:usage_percent] > 85 ? '⚠️' : '✅'
          output << "#{status} Memory Usage: #{mem[:usage_percent]}% (#{format_bytes(mem[:used_kb] * 1024)}/#{format_bytes(mem[:total_kb] * 1024)})"
        end

        if result[:disk]
          output << "\n💾 Disk Usage:"
          result[:disk].each do |mount, info|
            status = info[:usage_percent] > 90 ? '⚠️' : '✅'
            output << "  #{status} #{mount}: #{info[:usage_percent]}% (#{format_bytes(info[:used_bytes])}/#{format_bytes(info[:total_bytes])})"
          end
        end

        if result[:services]
          output << "\n🔧 Services:"
          result[:services].each do |service, info|
            status = info[:active] ? '✅' : '❌'
            output << "  #{status} #{service}: #{info[:status]}"
          end
        end

        output.join("\n")
      end

      def self.format_ssh_result(result)
        return "❌ SSH execution failed: #{result[:error]}" if result[:error]

        output = []
        output << '🔗 SSH Execution Result'
        output << ('=' * 30)
        output << "Host: #{result[:host]}"
        output << "Command: #{result[:command]}"
        output << "Exit Code: #{result[:exit_code]}"
        output << "Success: #{result[:success] ? '✅' : '❌'}"
        output << "\nOutput:"
        output << result[:stdout] unless result[:stdout].empty?

        output.join("\n")
      end

      def self.format_k8s_pods(pods)
        return "❌ Failed to get pods: #{pods[:error]}" if pods[:error]

        table = TTY::Table.new(
          header: %w[Name Namespace Status Ready Restarts Age],
          rows: pods.map do |pod|
            [
              pod[:name],
              pod[:namespace],
              pod[:status],
              pod[:ready] ? '✅' : '❌',
              pod[:restart_count],
              format_duration(pod[:age])
            ]
          end
        )

        "🐳 Kubernetes Pods\n" + table.render(:ascii)
      end

      def self.format_k8s_nodes(nodes)
        return "❌ Failed to get nodes: #{nodes[:error]}" if nodes[:error]

        table = TTY::Table.new(
          header: %w[Name Status CPU Memory Age],
          rows: nodes.map do |node|
            [
              node[:name],
              node[:status] == 'True' ? '✅ Ready' : '❌ Not Ready',
              node[:capacity]&.dig('cpu') || 'N/A',
              node[:capacity]&.dig('memory') || 'N/A',
              format_duration(node[:age])
            ]
          end
        )

        "🖥️  Kubernetes Nodes\n" + table.render(:ascii)
      end

      def self.format_gpt_analysis(result)
        return "❌ GPT analysis failed: #{result[:error]}" if result[:error]

        output = []
        output << '🤖 GPT Analysis'
        output << ('=' * 20)
        output << result[:analysis]
        output << "\nModel: #{result[:model]}"
        output << "Tokens used: #{result[:tokens_used]}"

        output.join("\n")
      end

      def self.format_log_analysis(result)
        return "❌ Log analysis failed: #{result[:error]}" if result[:error]

        output = []
        output << '📋 Log Analysis Report'
        output << ('=' * 30)
        output << "File: #{result[:file]}"
        output << "Total lines: #{result[:total_lines]}"
        output << "\nPattern Analysis:"

        result[:analysis].each do |pattern, data|
          output << "  #{pattern}: #{data[:count]} matches"
        end

        output.join("\n")
      end

      def self.format_notification_result(result)
        return "❌ Notification failed: #{result[:error]}" if result[:error]

        "✅ Notification sent successfully to #{result[:platform]}"
      end

      def self.format_bytes(bytes)
        return '0 B' if bytes.nil? || bytes == 0

        units = %w[B KB MB GB TB]
        size = bytes.to_f
        unit_index = 0

        while size >= 1024 && unit_index < units.length - 1
          size /= 1024
          unit_index += 1
        end

        "#{size.round(2)} #{units[unit_index]}"
      end

      def self.format_duration(seconds)
        return 'N/A' if seconds.nil?

        if seconds < 60
          "#{seconds.round(0)}s"
        elsif seconds < 3600
          "#{(seconds / 60).round(0)}m"
        elsif seconds < 86_400
          "#{(seconds / 3600).round(1)}h"
        else
          "#{(seconds / 86_400).round(1)}d"
        end
      end

      def self.colorize_status(status, text)
        case status.to_s.downcase
        when 'success', 'running', 'ready', 'true'
          text.green
        when 'error', 'failed', 'stopped', 'false'
          text.red
        when 'warning', 'pending'
          text.yellow
        else
          text.blue
        end
      end

      def self.progress_bar(current, total, width = 50)
        percentage = (current.to_f / total * 100).round(1)
        filled = (current.to_f / total * width).round
        empty = width - filled

        bar = ('█' * filled) + ('░' * empty)
        "[#{bar}] #{percentage}% (#{current}/#{total})"
      end
    end
  end
end

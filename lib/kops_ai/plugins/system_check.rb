# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

require 'sys/filesystem'

module KopsAI
  module Plugins
    # System resource monitoring plugin
    class SystemCheck < Core::Plugin
      def initialize
        super(
          name: 'system_check',
          description: 'Check system resources (CPU, memory, disk, services)',
          version: '1.0.0'
        )
      end

      def execute(check_type = 'all')
        case check_type.to_s
        when 'cpu'
          check_cpu
        when 'memory'
          check_memory
        when 'disk'
          check_disk
        when 'services'
          check_services
        when 'all'
          check_all
        else
          raise ArgumentError, "Unknown check type: #{check_type}"
        end
      end

      private

      def check_all
        {
          cpu: check_cpu,
          memory: check_memory,
          disk: check_disk,
          services: check_services,
          timestamp: Time.now.utc.iso8601
        }
      end

      def check_cpu
        cpu_info = File.read('/proc/stat').lines.first
        values = cpu_info.split[1..-1].map(&:to_i)
        total = values.sum
        idle = values[3]
        usage = ((total - idle).to_f / total * 100).round(2)

        {
          usage_percent: usage,
          cores: Etc.nprocessors,
          load_average: File.read('/proc/loadavg').split[0..2].map(&:to_f)
        }
      end

      def check_memory
        meminfo = File.read('/proc/meminfo')
        total = meminfo.match(/MemTotal:\s+(\d+)/)[1].to_i
        available = meminfo.match(/MemAvailable:\s+(\d+)/)[1].to_i
        used = total - available
        usage_percent = (used.to_f / total * 100).round(2)

        {
          total_kb: total,
          used_kb: used,
          available_kb: available,
          usage_percent: usage_percent
        }
      end

      def check_disk
        mounts = File.read('/proc/mounts').lines
        disk_info = {}

        mounts.each do |line|
          parts = line.split
          next unless parts[1].start_with?('/')

          mount_point = parts[1]
          filesystem = parts[0]
          next unless Dir.exist?(mount_point)

          begin
            stat = Sys::Filesystem.stat(mount_point)
            total = stat.blocks * stat.block_size
            available = stat.blocks_available * stat.block_size
            used = total - available
            usage_percent = (used.to_f / total * 100).round(2)

            disk_info[mount_point] = {
              filesystem: filesystem,
              total_bytes: total,
              used_bytes: used,
              available_bytes: available,
              usage_percent: usage_percent
            }
          rescue StandardError => e
            logger.warn("Failed to check disk usage for #{mount_point}", error: e.message)
          end
        end

        disk_info
      end

      def check_services
        services = %w[nginx apache2 mysql postgresql redis docker kubelet]
        service_status = {}

        services.each do |service|
          status = check_service_status(service)
          service_status[service] = status
        end

        service_status
      end

      def check_service_status(service)
        result = system('systemctl', 'is-active', '--quiet', service)
        {
          name: service,
          status: result ? 'running' : 'stopped',
          active: result
        }
      rescue StandardError => e
        {
          name: service,
          status: 'unknown',
          active: false,
          error: e.message
        }
      end
    end
  end
end

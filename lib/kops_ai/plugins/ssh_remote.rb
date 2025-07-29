# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

require 'net/ssh'

module KopsAI
  module Plugins
    # SSH remote execution plugin
    class SSHRemote < Core::Plugin
      def initialize
        super(
          name: 'ssh_remote',
          description: 'Execute commands on remote servers via SSH',
          version: '1.0.0'
        )
      end

      def execute(host:, command:, username: nil, password: nil, key_path: nil, timeout: nil)
        username ||= ENV['SSH_USERNAME'] || Etc.getlogin
        timeout ||= config.get(:ssh_timeout) || 30

        logger.info('Executing SSH command', host: host, command: command, username: username)

        Net::SSH.start(host, username, ssh_options(password, key_path, timeout)) do |ssh|
          result = ssh.exec!(command)
          {
            host: host,
            command: command,
            exit_code: ssh.exec!('echo $?').strip.to_i,
            stdout: result,
            stderr: '',
            success: ssh.exec!('echo $?').strip.to_i == 0
          }
        end
      rescue Net::SSH::AuthenticationFailed => e
        logger.error('SSH authentication failed', host: host, error: e.message)
        raise Error, "SSH authentication failed for #{host}: #{e.message}"
      rescue Net::SSH::ConnectionTimeout => e
        logger.error('SSH connection timeout', host: host, error: e.message)
        raise Error, "SSH connection timeout for #{host}: #{e.message}"
      rescue StandardError => e
        logger.error('SSH execution failed', host: host, error: e.message)
        raise Error, "SSH execution failed for #{host}: #{e.message}"
      end

      def available?
        require 'net/ssh'
        true
      rescue LoadError
        false
      end

      private

      def ssh_options(password, key_path, timeout)
        options = {
          timeout: timeout,
          non_interactive: true,
          verify_host_key: :never
        }

        if password
          options[:password] = password
        elsif key_path
          options[:keys] = [key_path]
        else
          # Try default SSH key locations
          default_keys = %w[~/.ssh/id_rsa ~/.ssh/id_ed25519 ~/.ssh/id_ecdsa]
          existing_keys = default_keys.select { |key| File.exist?(File.expand_path(key)) }
          options[:keys] = existing_keys.map { |key| File.expand_path(key) } if existing_keys.any?
        end

        options
      end
    end
  end
end

# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

module KopsAI
  module Plugins
    # Jenkins CI/CD integration plugin
    class JenkinsAgent < Core::Plugin
      def initialize
        super(
          name: 'jenkins_agent',
          description: 'Query Jenkins build status and trigger deployments',
          version: '1.0.0'
        )
      end

      def execute(action, **options)
        case action.to_s
        when 'jobs'
          list_jobs
        when 'build'
          trigger_build(options[:job_name], options[:parameters])
        when 'status'
          get_build_status(options[:job_name], options[:build_number])
        when 'logs'
          get_build_logs(options[:job_name], options[:build_number])
        else
          raise ArgumentError, "Unknown action: #{action}"
        end
      end

      def available?
        return false unless jenkins_url

        # Test connection
        test_connection
        true
      rescue StandardError
        false
      end

      private

      def jenkins_url
        config.get(:jenkins_url) || ENV.fetch('JENKINS_URL', nil)
      end

      def jenkins_username
        config.get(:jenkins_username) || ENV.fetch('JENKINS_USERNAME', nil)
      end

      def jenkins_token
        config.get(:jenkins_token) || ENV.fetch('JENKINS_TOKEN', nil)
      end

      def test_connection
        require 'httpx'
        response = HTTPX.get("#{jenkins_url}/api/json", auth: [jenkins_username, jenkins_token])
        response.raise_for_status
      rescue StandardError => e
        logger.error('Jenkins connection test failed', error: e.message)
        raise
      end

      def list_jobs
        require 'httpx'

        response = HTTPX.get(
          "#{jenkins_url}/api/json?tree=jobs[name,url,color,builds[number,result,timestamp]]",
          auth: [jenkins_username, jenkins_token]
        )
        response.raise_for_status

        data = JSON.parse(response.body.to_s)
        {
          jobs: data['jobs'].map do |job|
            {
              name: job['name'],
              url: job['url'],
              status: job['color'],
              last_build: job['builds']&.first
            }
          end
        }
      rescue StandardError => e
        logger.error('Failed to list Jenkins jobs', error: e.message)
        { error: e.message }
      end

      def trigger_build(job_name, parameters = {})
        require 'httpx'

        url = "#{jenkins_url}/job/#{job_name}/build"

        if parameters.any?
          url = "#{jenkins_url}/job/#{job_name}/buildWithParameters"
          response = HTTPX.post(url, form: parameters, auth: [jenkins_username, jenkins_token])
        else
          response = HTTPX.post(url, auth: [jenkins_username, jenkins_token])
        end

        if response.status == 201
          {
            success: true,
            job_name: job_name,
            message: 'Build triggered successfully'
          }
        else
          {
            success: false,
            job_name: job_name,
            error: "HTTP #{response.status}: #{response.body}"
          }
        end
      rescue StandardError => e
        logger.error('Failed to trigger Jenkins build', error: e.message, job: job_name)
        { error: e.message }
      end

      def get_build_status(job_name, build_number = nil)
        require 'httpx'

        url = if build_number
                "#{jenkins_url}/job/#{job_name}/#{build_number}/api/json"
              else
                "#{jenkins_url}/job/#{job_name}/lastBuild/api/json"
              end

        response = HTTPX.get(url, auth: [jenkins_username, jenkins_token])
        response.raise_for_status

        data = JSON.parse(response.body.to_s)
        {
          job_name: job_name,
          build_number: data['number'],
          result: data['result'],
          timestamp: data['timestamp'],
          duration: data['duration'],
          url: data['url']
        }
      rescue StandardError => e
        logger.error('Failed to get Jenkins build status', error: e.message, job: job_name)
        { error: e.message }
      end

      def get_build_logs(job_name, build_number = nil)
        require 'httpx'

        url = if build_number
                "#{jenkins_url}/job/#{job_name}/#{build_number}/consoleText"
              else
                "#{jenkins_url}/job/#{job_name}/lastBuild/consoleText"
              end

        response = HTTPX.get(url, auth: [jenkins_username, jenkins_token])
        response.raise_for_status

        {
          job_name: job_name,
          build_number: build_number,
          logs: response.body.to_s
        }
      rescue StandardError => e
        logger.error('Failed to get Jenkins build logs', error: e.message, job: job_name)
        { error: e.message }
      end
    end
  end
end

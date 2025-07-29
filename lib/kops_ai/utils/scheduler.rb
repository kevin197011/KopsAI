# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

require 'rufus-scheduler'

module KopsAI
  module Utils
    # Task scheduler for KopsAI
    class Scheduler
      def initialize
        @scheduler = Rufus::Scheduler.new
        @logger = KopsAI.logger
        @jobs = {}
      end

      # Schedule a task to run at a specific time
      def schedule_at(time, task_name, &block)
        job = @scheduler.at(time) do
          execute_task(task_name, &block)
        end

        @jobs[task_name] = job
        @logger.info('Task scheduled', task: task_name, time: time)
        job
      end

      # Schedule a task to run every interval
      def schedule_every(interval, task_name, &block)
        job = @scheduler.every(interval) do
          execute_task(task_name, &block)
        end

        @jobs[task_name] = job
        @logger.info('Task scheduled', task: task_name, interval: interval)
        job
      end

      # Schedule a task to run with cron expression
      def schedule_cron(cron_expression, task_name, &block)
        job = @scheduler.cron(cron_expression) do
          execute_task(task_name, &block)
        end

        @jobs[task_name] = job
        @logger.info('Task scheduled', task: task_name, cron: cron_expression)
        job
      end

      # Schedule a task to run in the future
      def schedule_in(delay, task_name, &block)
        job = @scheduler.in(delay) do
          execute_task(task_name, &block)
        end

        @jobs[task_name] = job
        @logger.info('Task scheduled', task: task_name, delay: delay)
        job
      end

      # Cancel a scheduled task
      def cancel_task(task_name)
        job = @jobs[task_name]
        return false unless job

        job.unschedule
        @jobs.delete(task_name)
        @logger.info('Task cancelled', task: task_name)
        true
      end

      # List all scheduled jobs
      def list_jobs
        @jobs.map do |name, job|
          {
            name: name,
            next_time: job.next_time,
            running: job.running?,
            original: job.original
          }
        end
      end

      # Start the scheduler
      def start
        @logger.info('Starting KopsAI scheduler')
        @scheduler.start
      end

      # Stop the scheduler
      def stop
        @logger.info('Stopping KopsAI scheduler')
        @scheduler.stop
      end

      # Check if scheduler is running
      def running?
        @scheduler.running?
      end

      # Join the scheduler thread (blocks until stopped)
      def join
        @scheduler.join
      end

      private

      def execute_task(task_name, &block)
        @logger.info('Executing scheduled task', task: task_name)
        start_time = Time.now

        begin
          result = block.call
          duration = Time.now - start_time
          @logger.info('Scheduled task completed', task: task_name, duration: duration, result: result)
          result
        rescue StandardError => e
          duration = Time.now - start_time
          @logger.error('Scheduled task failed', task: task_name, duration: duration, error: e.message)
          raise
        end
      end
    end
  end
end

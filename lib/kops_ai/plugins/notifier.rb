# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

module KopsAI
  module Plugins
    # Notification plugin for various platforms
    class Notifier < Core::Plugin
      def initialize
        super(
          name: 'notifier',
          description: 'Send notifications to DingTalk, Feishu, Telegram, etc.',
          version: '1.0.0'
        )
      end

      def execute(platform:, message:, title: nil, **options)
        case platform.to_s
        when 'dingtalk'
          send_dingtalk(message, title, options)
        when 'feishu'
          send_feishu(message, title, options)
        when 'telegram'
          send_telegram(message, title, options)
        when 'webhook'
          send_webhook(message, title, options)
        else
          raise ArgumentError, "Unsupported platform: #{platform}"
        end
      end

      private

      def send_dingtalk(message, title, options)
        webhook_url = options[:webhook_url] || config.get(:dingtalk_webhook)
        return { error: 'DingTalk webhook URL not configured' } unless webhook_url

        payload = {
          msgtype: 'markdown',
          markdown: {
            title: title || 'KopsAI Notification',
            text: format_dingtalk_message(message, options)
          }
        }

        send_http_request(webhook_url, payload)
      end

      def send_feishu(message, title, options)
        webhook_url = options[:webhook_url] || config.get(:feishu_webhook)
        return { error: 'Feishu webhook URL not configured' } unless webhook_url

        payload = {
          msg_type: 'post',
          content: {
            post: {
              zh_cn: {
                title: title || 'KopsAI Notification',
                content: format_feishu_content(message, options)
              }
            }
          }
        }

        send_http_request(webhook_url, payload)
      end

      def send_telegram(message, title, options)
        bot_token = options[:bot_token] || config.get(:telegram_bot_token)
        chat_id = options[:chat_id] || config.get(:telegram_chat_id)

        return { error: 'Telegram bot token or chat ID not configured' } unless bot_token && chat_id

        webhook_url = "https://api.telegram.org/bot#{bot_token}/sendMessage"
        payload = {
          chat_id: chat_id,
          text: format_telegram_message(message, title, options),
          parse_mode: 'Markdown'
        }

        send_http_request(webhook_url, payload)
      end

      def send_webhook(message, title, options)
        webhook_url = options[:webhook_url] || config.get(:notification_webhook)
        return { error: 'Webhook URL not configured' } unless webhook_url

        payload = {
          title: title || 'KopsAI Notification',
          message: message,
          timestamp: Time.now.utc.iso8601,
          level: options[:level] || 'info'
        }.merge(options)

        send_http_request(webhook_url, payload)
      end

      def send_http_request(url, payload)
        require 'httpx'

        response = HTTPX.post(url, json: payload, timeout: 10)

        if response.status == 200
          {
            success: true,
            platform: url,
            response: response.body.to_s
          }
        else
          {
            success: false,
            platform: url,
            error: "HTTP #{response.status}: #{response.body}"
          }
        end
      rescue StandardError => e
        logger.error('Notification failed', error: e.message, url: url)
        {
          success: false,
          platform: url,
          error: e.message
        }
      end

      def format_dingtalk_message(message, options)
        timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
        level = options[:level] || 'info'

        <<~MARKDOWN
          ## #{options[:title] || 'KopsAI Notification'}

          **Level:** #{level.upcase}
          **Time:** #{timestamp}

          #{message}

          #{"\n**Details:**\n#{options[:details]}" if options[:details]}
        MARKDOWN
      end

      def format_feishu_content(message, options)
        timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
        level = options[:level] || 'info'

        content = [
          ['Level', level.upcase],
          ['Time', timestamp],
          ['Message', message]
        ]

        content << ['Details', options[:details]] if options[:details]

        content
      end

      def format_telegram_message(message, title, options)
        timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
        level = options[:level] || 'info'

        <<~MARKDOWN
          *#{title || 'KopsAI Notification'}*

          **Level:** #{level.upcase}
          **Time:** #{timestamp}

          #{message}

          #{"\n**Details:**\n#{options[:details]}" if options[:details]}
        MARKDOWN
      end
    end
  end
end

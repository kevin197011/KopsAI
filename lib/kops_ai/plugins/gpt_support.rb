# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

module KopsAI
  module Plugins
    # OpenAI GPT integration plugin
    class GPTSupport < Core::Plugin
      def initialize
        super(
          name: 'gpt_support',
          description: 'Integrate with OpenAI GPT for intelligent analysis and suggestions',
          version: '1.0.0'
        )
        @client = nil
      end

      def execute(action, **options)
        case action.to_s
        when 'analyze_log'
          analyze_log(options[:log_content], options[:context])
        when 'suggest_fix'
          suggest_fix(options[:issue], options[:context])
        when 'explain_command'
          explain_command(options[:command])
        when 'generate_script'
          generate_script(options[:task], options[:language])
        else
          raise ArgumentError, "Unknown action: #{action}"
        end
      end

      def available?
        return false unless api_key

        # Test connection
        test_connection
        true
      rescue StandardError
        false
      end

      private

      def api_key
        config.get(:openai_api_key) || ENV.fetch('OPENAI_API_KEY', nil)
      end

      def model
        config.get(:openai_model) || 'gpt-4'
      end

      def client
        return @client if @client

        require 'ruby-openai'
        @client = OpenAI::Client.new(access_token: api_key)
      end

      def test_connection
        client.chat(
          parameters: {
            model: model,
            messages: [{ role: 'user', content: 'Hello' }],
            max_tokens: 10
          }
        )
      rescue StandardError => e
        logger.error('OpenAI API test failed', error: e.message)
        raise
      end

      def analyze_log(log_content, context = '')
        prompt = build_log_analysis_prompt(log_content, context)

        response = client.chat(
          parameters: {
            model: model,
            messages: [{ role: 'user', content: prompt }],
            max_tokens: 1000,
            temperature: 0.3
          }
        )

        {
          analysis: response.dig('choices', 0, 'message', 'content'),
          model: model,
          tokens_used: response.dig('usage', 'total_tokens')
        }
      rescue StandardError => e
        logger.error('Log analysis failed', error: e.message)
        { error: e.message }
      end

      def suggest_fix(issue, context = '')
        prompt = build_fix_suggestion_prompt(issue, context)

        response = client.chat(
          parameters: {
            model: model,
            messages: [{ role: 'user', content: prompt }],
            max_tokens: 1000,
            temperature: 0.3
          }
        )

        {
          suggestion: response.dig('choices', 0, 'message', 'content'),
          model: model,
          tokens_used: response.dig('usage', 'total_tokens')
        }
      rescue StandardError => e
        logger.error('Fix suggestion failed', error: e.message)
        { error: e.message }
      end

      def explain_command(command)
        prompt = build_command_explanation_prompt(command)

        response = client.chat(
          parameters: {
            model: model,
            messages: [{ role: 'user', content: prompt }],
            max_tokens: 500,
            temperature: 0.3
          }
        )

        {
          explanation: response.dig('choices', 0, 'message', 'content'),
          model: model,
          tokens_used: response.dig('usage', 'total_tokens')
        }
      rescue StandardError => e
        logger.error('Command explanation failed', error: e.message)
        { error: e.message }
      end

      def generate_script(task, language = 'bash')
        prompt = build_script_generation_prompt(task, language)

        response = client.chat(
          parameters: {
            model: model,
            messages: [{ role: 'user', content: prompt }],
            max_tokens: 1500,
            temperature: 0.3
          }
        )

        {
          script: response.dig('choices', 0, 'message', 'content'),
          language: language,
          model: model,
          tokens_used: response.dig('usage', 'total_tokens')
        }
      rescue StandardError => e
        logger.error('Script generation failed', error: e.message)
        { error: e.message }
      end

      def build_log_analysis_prompt(log_content, context)
        <<~PROMPT
          You are an expert DevOps engineer analyzing system logs. Please analyze the following log content and provide:

          1. Summary of what happened
          2. Potential issues or errors
          3. Recommended actions
          4. Severity level (Low/Medium/High/Critical)

          Context: #{context}

          Log content:
          #{log_content}

          Please provide a structured analysis in JSON format with the following fields:
          - summary: Brief description of events
          - issues: Array of identified problems
          - recommendations: Array of suggested actions
          - severity: Severity level
          - confidence: Confidence level (0-100)
        PROMPT
      end

      def build_fix_suggestion_prompt(issue, context)
        <<~PROMPT
          You are an expert DevOps engineer. Please provide a fix suggestion for the following issue:

          Issue: #{issue}
          Context: #{context}

          Please provide:
          1. Root cause analysis
          2. Step-by-step fix instructions
          3. Prevention measures
          4. Commands to execute (if applicable)

          Format your response as a structured JSON with:
          - root_cause: Brief explanation
          - steps: Array of fix steps
          - commands: Array of commands to run
          - prevention: Array of prevention measures
        PROMPT
      end

      def build_command_explanation_prompt(command)
        <<~PROMPT
          You are a DevOps expert. Please explain what this command does:

          Command: #{command}

          Please provide:
          1. What the command does
          2. Each parameter/flag explanation
          3. Common use cases
          4. Safety considerations

          Format as JSON with:
          - purpose: What it does
          - parameters: Object with parameter explanations
          - use_cases: Array of common uses
          - safety_notes: Array of safety considerations
        PROMPT
      end

      def build_script_generation_prompt(task, language)
        <<~PROMPT
          You are an expert DevOps engineer. Please generate a #{language} script for the following task:

          Task: #{task}

          Requirements:
          1. Include proper error handling
          2. Add comments explaining each step
          3. Make it production-ready
          4. Include logging
          5. Follow best practices

          Please provide only the script code, no explanations.
        PROMPT
      end
    end
  end
end

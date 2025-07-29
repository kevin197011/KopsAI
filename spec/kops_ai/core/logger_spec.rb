# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

require 'spec_helper'

RSpec.describe KopsAI::Core::Logger do
  let(:logger) { described_class.instance }

  describe '#info' do
    it 'logs info message' do
      expect { logger.info('Test message') }.not_to raise_error
    end

    it 'logs with context' do
      expect { logger.info('Test message', user_id: '123') }.not_to raise_error
    end
  end

  describe '#error' do
    it 'logs error message' do
      expect { logger.error('Test error') }.not_to raise_error
    end

    it 'logs error with exception' do
      error = StandardError.new('Test exception')
      expect { logger.error('Test error', error: error) }.not_to raise_error
    end
  end

  describe '#warn' do
    it 'logs warning message' do
      expect { logger.warn('Test warning') }.not_to raise_error
    end
  end

  describe '#debug' do
    it 'logs debug message' do
      expect { logger.debug('Test debug') }.not_to raise_error
    end
  end

  describe '#set_trace_id' do
    it 'sets trace ID' do
      logger.set_trace_id('test-123')
      expect(logger.send(:get_trace_id)).to eq('test-123')
    end
  end

  describe '#clear_trace_id' do
    it 'clears trace ID' do
      logger.set_trace_id('test-123')
      logger.clear_trace_id
      expect(logger.send(:get_trace_id)).to be_nil
    end
  end
end

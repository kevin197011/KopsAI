# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

require 'spec_helper'

RSpec.describe KopsAI::Plugins::SystemCheck do
  let(:plugin) { described_class.new }

  describe '#execute' do
    context "with 'all' check type" do
      it 'returns system information' do
        result = plugin.execute('all')
        expect(result).to be_a(Hash)
        expect(result).to have_key(:timestamp)
      end
    end

    context "with 'cpu' check type" do
      it 'returns CPU information' do
        result = plugin.execute('cpu')
        expect(result).to be_a(Hash)
        expect(result).to have_key(:usage_percent)
        expect(result).to have_key(:cores)
        expect(result).to have_key(:load_average)
      end
    end

    context "with 'memory' check type" do
      it 'returns memory information' do
        result = plugin.execute('memory')
        expect(result).to be_a(Hash)
        expect(result).to have_key(:total_kb)
        expect(result).to have_key(:used_kb)
        expect(result).to have_key(:available_kb)
        expect(result).to have_key(:usage_percent)
      end
    end

    context "with 'disk' check type" do
      it 'returns disk information' do
        result = plugin.execute('disk')
        expect(result).to be_a(Hash)
        # Disk info should contain mount points
        expect(result.keys).to all(be_a(String))
      end
    end

    context "with 'services' check type" do
      it 'returns service information' do
        result = plugin.execute('services')
        expect(result).to be_a(Hash)
        # Should contain service status information
        expect(result.keys).to all(be_a(String))
      end
    end

    context 'with unknown check type' do
      it 'raises ArgumentError' do
        expect { plugin.execute('unknown') }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#available?' do
    it 'returns true' do
      expect(plugin.available?).to be true
    end
  end

  describe '#info' do
    it 'returns plugin information' do
      info = plugin.info
      expect(info).to be_a(Hash)
      expect(info[:name]).to eq('system_check')
      expect(info[:description]).to include('system resources')
      expect(info[:version]).to eq('1.0.0')
      expect(info[:available]).to be true
    end
  end
end

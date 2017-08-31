# frozen_string_literal: true

RSpec.describe Iface::IpAddress do
  let(:ip_address) { described_class.new(ip_string) }

  context '?' do
    let(:ip_string) { '192.168.10.1' }

    it 'does something' do
      expect(ip_address).to be_truthy
    end
  end
end

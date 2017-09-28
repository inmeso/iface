# frozen_string_literal: true

RSpec.shared_context 'IPv4' do
  let(:ip4_string) { '192.168.10.10' }
  let(:ip4_int) { 192 * 256**3 + 168 * 256**2 + 10 * 256 + 10 }
end

RSpec.shared_context 'IPv6' do
  let(:ip6_string) { '2001:abcd:1234::2' }
  let(:ip6_int) do
    '20'.to_i(16) * 256**15 +
      '01'.to_i(16) * 256**14 +
      'ab'.to_i(16) * 256**13 +
      'cd'.to_i(16) * 256**12 +
      '12'.to_i(16) * 256**11 +
      '34'.to_i(16) * 256**10 +
      2
  end
end

RSpec.describe Iface::IpAddress do
  include_context 'IPv4'
  include_context 'IPv6'

  let(:ip4_mask) { 24 }
  let(:ip4_string_with_mask) { "#{ip4_string}/#{ip4_mask}" }
  let(:ip4_string_with_full_mask) { "#{ip4_string}/32" }

  let(:ip6_mask) { 48 }
  let(:ip6_string_with_mask) { "#{ip6_string}/#{ip6_mask}" }
  let(:ip6_string_with_full_mask) { "#{ip6_string}/128" }

  # let(:ip_address) { described_class.new(ip_string) }

  describe '::create' do
    context 'with IPv4 string' do
      it 'returns an instance of IpV4Address' do
        expect(described_class.create(ip4_string)).to be_an Iface::IpV4Address
      end
    end

    context 'with IPv6 string' do
      it 'returns an instance of IpV6Address' do
        expect(described_class.create(ip6_string)).to be_an Iface::IpV6Address
      end
    end
  end

  describe '#cidr_mask' do
    context 'with IPv4 string with mask' do
      it 'returns the mask' do
        expect(described_class.create(ip4_string_with_mask).cidr_mask).to eq ip4_mask
      end
    end

    context 'with IPv4 string with full mask' do
      it 'returns the mask' do
        expect(described_class.create(ip4_string_with_full_mask).cidr_mask).to eq 32
      end
    end

    context 'with IPv6 string with mask' do
      it 'returns the mask' do
        expect(described_class.create(ip6_string_with_mask).cidr_mask).to eq ip6_mask
      end
    end

    context 'with IPv6 string with full mask' do
      it 'returns the mask' do
        expect(described_class.create(ip6_string_with_full_mask).cidr_mask).to eq 128
      end
    end
  end

  describe '#full_mask' do
    context 'with IPv4 string' do
      it 'returns 2^32 - 1' do
        expect(described_class.create(ip4_string).full_mask).to eq 2**32 - 1
      end
    end

    context 'with IPv6 string' do
      it 'returns 2^128 - 1' do
        expect(described_class.create(ip6_string).full_mask).to eq 2**128 - 1
      end
    end
  end

  describe '#to_i' do
    context 'with IPv4 string' do
      it 'returns the integer value' do
        expect(described_class.create(ip4_string).to_i).to eq ip4_int
      end
    end

    context 'with IPv6 string' do
      it 'returns the integer value' do
        expect(described_class.create(ip6_string).to_i).to eq ip6_int
      end
    end
  end
end

RSpec.describe Iface::IpV4Address do
  include_context 'IPv4'

  describe '::from_numeric' do
    it 'returns the IpV4Address' do
      expect(described_class.from_numeric(ip4_int)).to eq described_class.new(ip4_string)
    end
  end
end

RSpec.describe Iface::IpV6Address do
  include_context 'IPv6'

  describe '::from_numeric' do
    it 'returns the IpV6Address' do
      expect(described_class.from_numeric(ip6_int)).to eq described_class.new(ip6_string)
    end
  end
end

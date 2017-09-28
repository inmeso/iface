# frozen_string_literal: true

RSpec.shared_context 'value_set' do
  let(:value_set) { Iface::ValueSet.new(StringIO.new('')) }
end

RSpec.describe Iface::ValueSet::Pair do
  include_context 'value_set'

  describe '::create' do
    context 'with one argument (NAME=value)' do
      context 'bad syntax' do
        it 'raises an ArgumentError' do
          expect { described_class.create('foo', value_set: value_set) }.to raise_error(ArgumentError, /expected pattern/i)
          expect { described_class.create('FOO', value_set: value_set) }.to raise_error(ArgumentError, /expected pattern/i)
        end
      end

      context 'good syntax' do
        it 'parses the pairs correctly' do
          [
            %w[FOO=bar FOO bar],
            %w[FOO="baz" FOO baz],
            ['FOO= baz', 'FOO', ' baz']
          ].each do |text, name, value|
            pair1 = described_class.create(text, value_set: value_set)
            expect(pair1.name).to eq name
            expect(pair1.value).to eq value
          end
        end
      end
    end

    context 'with two arguments' do
      it 'uses the arguments as name and value' do
        pair = described_class.create('FOO', 'bar', value_set: value_set)
        expect(pair.name).to eq 'FOO'
        expect(pair.value).to eq 'bar'
      end
    end

    context 'with name IPADDR' do
      context 'with one argument' do
        it 'returns a IpV4Primary pair' do
          pair = described_class.create('IPADDR=192.168.20.30', value_set: value_set)
          expect(pair).to be_a Iface::ValueSet::IpV4Primary
          expect(pair.name).to eq 'IPADDR'
          expect(pair.value).to eq '192.168.20.30'
        end
      end

      context 'with two arguments' do
        it 'returns a IpV4Primary pair' do
          pair = described_class.create('IPADDR', '192.168.20.30', value_set: value_set)
          expect(pair).to be_a Iface::ValueSet::IpV4Primary
          expect(pair.name).to eq 'IPADDR'
          expect(pair.value).to eq '192.168.20.30'
        end
      end
    end

    context 'with name IPV6ADDR' do
      context 'with one argument' do
        it 'returns a IpV6Primary pair' do
          pair = described_class.create('IPV6ADDR=2001:cdef:4567::10/56', value_set: value_set)
          expect(pair).to be_a Iface::ValueSet::IpV6Primary
          expect(pair.name).to eq 'IPV6ADDR'
          expect(pair.value).to eq '2001:cdef:4567::10/56'
        end
      end

      context 'with two arguments' do
        it 'returns a IpV6Primary pair' do
          pair = described_class.create('IPV6ADDR', '2001:cdef:4567::10/56', value_set: value_set)
          expect(pair).to be_a Iface::ValueSet::IpV6Primary
          expect(pair.name).to eq 'IPV6ADDR'
          expect(pair.value).to eq '2001:cdef:4567::10/56'
        end
      end
    end

    context 'with name IPV6ADDR_SECONDARIES' do
      context 'with one argument' do
        it 'returns a IpV6Secondaries pair' do
          pair = described_class.create('IPV6ADDR_SECONDARIES="2001:cdef:4567::10/56 2001:cdef:4567::11/56 2001:cdef:4567::12/56"', value_set: value_set)
          expect(pair).to be_a Iface::ValueSet::IpV6Secondaries
          expect(pair.name).to eq 'IPV6ADDR_SECONDARIES'
          expect(pair.value).to eq '2001:cdef:4567::10/56 2001:cdef:4567::11/56 2001:cdef:4567::12/56'
        end
      end

      context 'with two arguments' do
        it 'returns a IpV6Secondaries pair' do
          pair = described_class.create('IPV6ADDR_SECONDARIES', '2001:cdef:4567::10/56 2001:cdef:4567::11/56 2001:cdef:4567::12/56', value_set: value_set)
          expect(pair).to be_a Iface::ValueSet::IpV6Secondaries
          expect(pair.name).to eq 'IPV6ADDR_SECONDARIES'
          expect(pair.value).to eq '2001:cdef:4567::10/56 2001:cdef:4567::11/56 2001:cdef:4567::12/56'
        end
      end
    end
  end

  describe '#value=' do
    it 'updates the value' do
      pair = described_class.create('FOO=bar', value_set: value_set)
      expect(pair.value).to eq 'bar'
      pair.value = 'baz'
      expect(pair.value).to eq 'baz'
    end
  end

  describe '#to_s' do
    it 'returns NAME=value' do
      [
        %w[FOO=bar FOO="bar"],
        %w[FOO="baz" FOO="baz"],
        ['FOO= baz', 'FOO=" baz"']
      ].each do |text, result|
        expect(described_class.create(text, value_set: value_set).to_s).to eq result
      end
    end
  end
end

RSpec.describe Iface::ValueSet::IpV4Primary do
  include_context 'value_set'

  describe '::new' do
    let(:ip4_string) { '200.201.202.203' }
    let(:pair) { described_class.new('IPADDR', ip4_string, value_set) }

    context 'with arbitrary name' do
      let(:pair) { described_class.new('FOO', ip4_string, value_set) }

      it 'returns the expected name' do
        expect(pair.name).to eq 'IPADDR'
      end
    end

    context 'with invalid IPv4 address' do
      let(:ip4_string) { 'foo' }

      it 'raises an ArgumentError' do
        expect { pair }.to raise_error ArgumentError
      end
    end

    context 'with valid IPv4 address' do
      it 'returns a correct value' do
        expect(pair.value).to eq ip4_string
      end
    end
  end

  describe '#value=' do
    let(:pair) { described_class.new('IPADDR', '10.1.2.3', value_set) }

    context 'with an invalid IPv4 address' do
      it 'raises an ArgumentError' do
        expect { pair.value = 'foo' }.to raise_error(ArgumentError)
        expect { pair.value = '2001::2' }.to raise_error(ArgumentError)
      end
    end

    context 'with a valid IPv4 address' do
      it 'updates the value' do
        pair.value = '12.13.14.15'
        expect(pair.value).to eq '12.13.14.15'
      end
    end
  end
end

RSpec.describe Iface::ValueSet::IpV6Primary do
  include_context 'value_set'

  describe '::new' do
    let(:ip6_string) { '2001:bcde::24/96' }
    let(:pair) { described_class.new('IPV6ADDR', ip6_string, value_set) }

    context 'with arbitrary name' do
      let(:pair) { described_class.new('FOO', ip6_string, value_set) }

      it 'returns the expected name' do
        expect(pair.name).to eq 'IPV6ADDR'
      end
    end

    context 'with invalid IPv6 address' do
      let(:ip6_string) { 'foo' }

      it 'raises an ArgumentError' do
        expect { pair }.to raise_error ArgumentError
      end
    end

    context 'with valid IPv6 address' do
      it 'returns a correct value' do
        expect(pair.value).to eq ip6_string
      end
    end
  end

  describe '#value=' do
    let(:pair) { described_class.new('IPV6ADDR', '2001:abcd::12/48', value_set) }

    context 'with an invalid IPv6 address' do
      it 'raises an ArgumentError' do
        expect { pair.value = 'foo' }.to raise_error ArgumentError
        expect { pair.value = '100.101.102.103' }.to raise_error ArgumentError
      end
    end

    context 'with a valid IPv6 address' do
      it 'updates the value' do
        pair.value = '2010::2011/56'
        expect(pair.value).to eq '2010::2011/56'
      end
    end
  end
end

RSpec.describe Iface::ValueSet::IpV6Secondaries do
  include_context 'value_set'

  let(:ip6_string) { '2001::4/48' }
  let(:ip6_int) { IPAddr.new(ip6_string[%r{^(.*)/.*$}, 1]).to_i }
  let(:ip6_strings) { %w[2001::5/48 2001::3/48] + [ip6_string] }
  let(:ip6_strings_sorted) { ip6_strings.sort.map(&:to_s) }
  let(:pair) { described_class.new('IPV6ADDR_SECONDARIES', ip6_strings, value_set) }

  describe '::new' do
    shared_examples '::new' do
      context 'with invalid IPv6 addresses' do
        let(:ip6_string) { 'foo' }

        it 'raises an ArgumentError' do
          expect { pair }.to raise_error(ArgumentError)
        end
      end

      context 'with valid IPv6 addresses' do
        it 'sorts the addresses' do
          expect(pair.value).to eq ip6_strings_sorted.join(' ')
        end
      end
    end

    context 'with arbitrary name' do
      let(:pair) { described_class.new('FOO', ip6_strings.join(' '), value_set) }

      it 'returns the expected name' do
        expect(pair.name).to eq 'IPV6ADDR_SECONDARIES'
      end
    end

    context 'with String value' do
      let(:pair) { described_class.new('IPV6ADDR_SECONDARIES', ip6_strings.join(' '), value_set) }
      include_examples '::new'
    end

    context 'with Array value' do
      include_examples '::new'
    end
  end

  describe '#filter_primary' do
    it 'removes the matching IPv6 address from the value' do
      initial_value = pair.value
      expected_value = initial_value.sub(ip6_string, '').gsub(/ +/, ' ').strip
      pair.filter_primary!(ip6_int)
      expect(pair.value).to eq expected_value
    end
  end
end

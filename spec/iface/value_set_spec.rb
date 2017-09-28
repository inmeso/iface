# frozen_string_literal: true

RSpec.describe Iface::ValueSet do
  let(:ipaddr) { '192.168.10.1' }
  let(:ipaddr_raw) { 192 * 256**3 + 168 * 256**2 + 10 * 256 + 1 }

  let(:hash) do
    {
      'FOO' => 'bar',
      'BAR' => 'baz',
      'PHRED' => 'smerd',
      'IPADDR' => ipaddr
    }
  end

  let(:value_set) do
    described_class.new(StringIO.new(hash.map { |k, v| %(#{k}="#{v}") }.join("\n")))
  end

  describe '#[]' do
    context 'name exists' do
      it 'returns the value' do
        expect(value_set['foo']).to eq 'bar'
        expect(value_set['bar']).to eq 'baz'
        expect(value_set['PHRED']).to eq 'smerd'
      end
    end

    context 'name does not exist' do
      it 'returns nil' do
        expect(value_set['baz']).to be_nil
        expect(value_set['smerd']).to be_nil
      end
    end
  end

  describe '#[]=' do
    context 'name exists' do
      it 'updates the value' do
        expect(value_set['PHRED']).to eq 'smerd'
        value_set['PHRED'] = 'smith'
        expect(value_set['PHRED']).to eq 'smith'
      end
    end

    context 'name does not exist' do
      it 'creates the name/value pair' do
        expect(value_set).to_not have_key 'ALPHA'
        value_set['ALPHA'] = 'bravo'
        expect(value_set['ALPHA']).to eq 'bravo'
      end
    end
  end

  describe '#fetch_raw' do
    context 'name exists' do
      it 'returns the raw value' do
        expect(value_set.fetch_raw('foo')).to eq 'bar'
        expect(value_set.fetch_raw('bar')).to eq 'baz'
        expect(value_set.fetch_raw('PHRED')).to eq 'smerd'
        expect(value_set.fetch_raw('ipaddr')).to eq ipaddr_raw
      end
    end

    context 'name does not exist' do
      it 'returns nil' do
        expect(value_set.fetch_raw('baz')).to be_nil
        expect(value_set.fetch_raw('smerd')).to be_nil
      end
    end
  end

  describe '#key?' do
    context 'name exists' do
      it 'returns true' do
        expect(value_set.key?('foo')).to eq true
        expect(value_set.key?('bar')).to eq true
        expect(value_set.key?('PHRED')).to eq true
      end
    end

    context 'name does not exist' do
      it 'returns nil' do
        expect(value_set.key?('baz')).to eq false
        expect(value_set.key?('smerd')).to eq false
      end
    end
  end

  describe '#to_s' do
    it 'returns a deserialized list of NAME=value pairs' do
      expect(value_set.to_s).to eq %(FOO="bar"\nBAR="baz"\nPHRED="smerd"\nIPADDR="192.168.10.1"\n)
    end
  end
end

RSpec.describe Iface::PrimaryInterface do
  let(:ipaddr) { '192.168.10.1' }
  # let(:ipaddr_raw) { 192 * 256**3 + 168 * 256**2 + 10 * 256 + 1 }

  let(:hash) do
    {
      'BOOTPROTO' => 'dhcp',
      'NM_CONTROLLED' => 'yes',
      'IPADDR' => ipaddr,
      'IPV6INIT' => 'no'
    }
  end

  let(:value_set) do
    described_class.new(StringIO.new(hash.map { |k, v| %(#{k}="#{v}") }.join("\n")))
  end

  describe '#make_static' do
    context 'BOOTPROTO does not exist' do
      it 'adds BOOTPROTO=none to the set' do
        hash.delete('BOOTPROTO')
        expect(value_set).to_not have_key 'BOOTPROTO'
        value_set.make_static
        expect(value_set['bootproto']).to eq 'none'
      end
    end

    context 'BOOTPROTO exists' do
      it 'updates the value of BOOTPROTO to none' do
        expect(value_set['bootproto']).to eq 'dhcp'
        value_set.make_static
        expect(value_set['bootproto']).to eq 'none'
      end
    end
  end

  describe '#disable_nm' do
    context 'NM_CONTROLLED does not exist' do
      it 'adds NM_CONTROLLED=no to the set' do
        hash.delete('NM_CONTROLLED')
        expect(value_set).to_not have_key 'NM_CONTROLLED'
        value_set.disable_nm
        expect(value_set['nm_controlled']).to eq 'no'
      end
    end

    context 'NM_CONTROLLED exists' do
      it 'updates the value of NM_CONTROLLED to no' do
        expect(value_set['nm_controlled']).to eq 'yes'
        value_set.disable_nm
        expect(value_set['nm_controlled']).to eq 'no'
      end
    end
  end

  describe '#use_ipv6' do
    context 'IPV6INIT does not exist' do
      it 'adds IPV6INIT=yes to the set' do
        hash.delete('IPV6INIT')
        expect(value_set).to_not have_key 'IPV6INIT'
        value_set.use_ipv6
        expect(value_set['ipv6init']).to eq 'yes'
      end
    end

    context 'IPV6INIT exists' do
      it 'updates the value of IPV6INIT to yes' do
        expect(value_set['ipv6init']).to eq 'no'
        value_set.use_ipv6
        expect(value_set['ipv6init']).to eq 'yes'
      end
    end
  end
end

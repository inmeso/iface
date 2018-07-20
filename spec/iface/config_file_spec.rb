# frozen_string_literal: true

RSpec.shared_context 'config files' do
  let(:ipaddr) { '173.208.232.2' }
  let(:ipaddr_middle) { '173.208.232.12' }
  let(:ipaddr_end) { '173.208.232.30' }
  let(:clone_num) { 123 }
  let(:range_num) { 456 }
  let(:clonenum_start) { 24 }

  let(:primary_file) do
    [
      'ifcfg-eth0',
      StringIO.new(<<~__EOF__)
        DEVICE=eth0
        BOOTPROTO=none
        HWADDR=00:30:48:d7:04:48
        NM_CONTROLLED=yes
        ONBOOT=yes
        TYPE=Ethernet
        UUID="08562816-c7ce-4364-8cbd-2505faee246e"
        IPADDR=#{ipaddr}
        NETMASK=255.255.255.248
        GATEWAY=173.208.232.89
        USERCTL=no
        PEERDNS=yes
        IPV6INIT=no
      __EOF__
    ]
  end

  let(:clone_file) do
    [
      "ifcfg-venet0:#{clone_num}",
      StringIO.new(<<~__EOF__)
        DEVICE=venet0:#{clone_num}
        ONBOOT=yes
        IPADDR=#{ipaddr}
        ARPCHECK="no"
        NM_CONTROLLED="yes"
        NETMASK=255.255.255.255
      __EOF__
    ]
  end

  let(:range_file) do
    [
      "ifcfg-eth1-range#{range_num}",
      StringIO.new(<<~__EOF__)
        IPADDR_START=#{ipaddr}
        IPADDR_END=#{ipaddr_end}
        CLONENUM_START=#{clonenum_start}
        NETMASK=255.255.255.0
        ARPCHECK=no
      __EOF__
    ]
  end
end

RSpec.describe Iface::ConfigFile do
  include_context 'config files'

  describe '::parse_filename' do
    context 'simple interface file name' do
      it 'returns the device name' do
        expect(described_class.parse_filename('ifcfg-eth0')).to eq ['eth0', nil, nil, nil]
        expect(described_class.parse_filename('ifcfg-lo')).to eq ['lo', nil, nil, nil]
        expect(described_class.parse_filename('ifcfg-venet0')).to eq ['venet0', nil, nil, nil]
      end
    end

    context 'VLAN file name' do
      it 'returns the device name and VLAN ID' do
        expect(described_class.parse_filename('ifcfg-eth0.123')).to eq ['eth0', 123, nil, nil]
        expect(described_class.parse_filename('ifcfg-eth1.10')).to eq ['eth1', 10, nil, nil]
      end
    end

    context 'range file name' do
      it 'returns the device name and range number' do
        expect(described_class.parse_filename('ifcfg-eth0-range0')).to eq ['eth0', nil, 0, nil]
        expect(described_class.parse_filename('ifcfg-eth1-range10')).to eq ['eth1', nil, 10, nil]
      end
    end

    context 'clone file name' do
      it 'returns the device name and clone number' do
        expect(described_class.parse_filename('ifcfg-eth0:0')).to eq ['eth0', nil, nil, 0]
        expect(described_class.parse_filename('ifcfg-eth1:12')).to eq ['eth1', nil, nil, 12]
        expect(described_class.parse_filename('ifcfg-venet0:999')).to eq ['venet0', nil, nil, 999]
      end
    end
  end

  describe '::create' do
    context 'primary file' do
      it 'returns a PrimaryFile' do
        expect(described_class.create(*primary_file)).to be_a Iface::PrimaryFile
      end
    end

    context 'clone file' do
      it 'returns a CloneFile' do
        expect(described_class.create(*clone_file)).to be_a Iface::CloneFile
      end
    end

    context 'range file' do
      it 'returns a RangeFile' do
        expect(described_class.create(*range_file)).to be_a Iface::RangeFile
      end
    end
  end
end

RSpec.describe Iface::PrimaryFile do
  include_context 'config files'

  let(:config_file) { described_class.create(*primary_file) }

  context 'static' do
    context '#ip_address' do
      it 'returns the IP address' do
        expect(config_file.ip_address).to eq ipaddr
      end
    end

    context '#ip_address=' do
      it 'updates the IP address' do
        config_file.ip_address = '8.7.6.5'
        expect(config_file.ip_address).to eq '8.7.6.5'
      end
    end

    context 'ipv6_address=' do
      it 'updates the IPv6 address' do
        config_file.ipv6_address = '2016::2018/120'
        expect(config_file.ipv6_address).to eq '2016::2018/120'
      end
    end

    context 'ipv6_secondaries=' do
      it 'updates the IPv6 secondary addresses' do
        ipv6_secondaries = %w[2001::2/64 2001::3/64 2001::4/64]
        config_file.ipv6_secondaries = ipv6_secondaries
        expect(config_file.ipv6_secondaries).to eq ipv6_secondaries
      end
    end

    context '#static?' do
      it 'returns true' do
        expect(config_file.static?).to eq true
      end
    end

    context '#include?' do
      context 'IP matches' do
        it 'returns true' do
          expect(config_file.include?(ipaddr)).to eq true
        end
      end

      context 'IP does not match' do
        it 'returns false' do
          expect(config_file.include?('10.0.0.0')).to eq false
        end
      end
    end
  end

  context 'dhcp' do
    shared_examples 'updated IPs' do
      it 'sets config file to static' do
        config_file.ipv6_address = '2018::2020/56'
        expect(config_file).to be_static
      end

      it 'disables NetworkManager' do
        config_file.ip_address = '12.14.16.18'
        expect(config_file).to_not be_nm_controlled
      end
    end

    let(:primary_file) do
      [
        'ifcfg-eth0',
        StringIO.new(<<~__EOF__)
          DEVICE=eth0
          BOOTPROTO=dhcp
          ONBOOT=yes
          TYPE=Ethernet
        __EOF__
      ]
    end

    context '#ip_address=' do
      it 'adds the IP address' do
        config_file.ip_address = '8.7.6.5'
        expect(config_file.ip_address).to eq '8.7.6.5'
      end

      include_examples 'updated IPs'
    end

    context 'ipv6_address=' do
      it 'adds the IPv6 address' do
        config_file.ipv6_address = '2016::2018/120'
        expect(config_file.ipv6_address).to eq '2016::2018/120'
      end

      include_examples 'updated IPs'
    end

    context 'ipv6_secondaries=' do
      ipv6_secondaries = %w[2001::2/64 2001::3/64 2001::4/64]

      it 'adds the IPv6 secondary addresses' do
        config_file.ipv6_secondaries = ipv6_secondaries
        expect(config_file.ipv6_secondaries).to eq ipv6_secondaries
      end

      include_examples 'updated IPs'
    end

    context '#static?' do
      it 'returns false' do
        expect(config_file.static?).to eq false
      end
    end

    context '#include?' do
      it 'returns false' do
        expect(config_file.include?(ipaddr)).to eq false
      end
    end
  end
end

RSpec.describe Iface::CloneFile do
  include_context 'config files'

  let(:config_file) { described_class.create(*clone_file) }

  context '#ip_address' do
    it 'returns the IP address' do
      expect(config_file.ip_address).to eq ipaddr
    end
  end

  context '#clone_num' do
    it 'returns the clone number' do
      expect(config_file.clone_num).to eq clone_num
    end
  end

  context '#static?' do
    it 'returns true' do
      expect(config_file.static?).to eq true
    end
  end

  context '#include?' do
    context 'IP matches' do
      it 'returns true' do
        expect(config_file.include?(ipaddr)).to eq true
      end
    end

    context 'IP does not match' do
      it 'returns false' do
        expect(config_file.include?('10.0.0.0')).to eq false
      end
    end
  end
end

RSpec.describe Iface::RangeFile do
  include_context 'config files'

  let(:config_file) { described_class.create(*range_file) }

  context '#start_clone_num' do
    it 'returns the starting clone number' do
      expect(config_file.start_clone_num).to eq clonenum_start
    end
  end

  context '#static?' do
    it 'returns true' do
      expect(config_file.static?).to eq true
    end
  end

  context '#include?' do
    context 'IP is within the range' do
      it 'returns true' do
        expect(config_file.include?(ipaddr_middle)).to eq true
      end
    end

    context 'IP is not within the range' do
      it 'returns false' do
        expect(config_file.include?('10.0.0.0')).to eq false
      end
    end
  end
end

RSpec.describe Iface::VlanFile do
  let(:ipaddr) { '10.11.12.13' }
  let(:vlan_id) { 123 }

  let(:vlan_file) do
    [
      "ifcfg-eth0.#{vlan_id}",
      StringIO.new(<<~__EOF__)
        DEVICE=eth0.#{vlan_id}
        ONBOOT=yes
        BOOTPROTO=none
        IPADDR=#{ipaddr}
        VLAN=yes
      __EOF__
    ]
  end

  let(:config_file) { described_class.create(*vlan_file) }

  context '#vlan_id' do
    it 'returns the correct VLAN ID' do
      expect(config_file.vlan_id).to eq vlan_id
    end
  end

  context '#static?' do
    it 'returns true' do
      expect(config_file.static?).to eq true
    end
  end
end

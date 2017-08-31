# frozen_string_literal: true

RSpec.describe Iface::ConfigFile do
  let(:bootproto) { 'none' }
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
        BOOTPROTO=#{bootproto}
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
        NM_CONTROLLED="no"
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

  describe '::parse_filename' do
    context 'simple interface file name' do
      it 'returns the device name' do
        expect(described_class.parse_filename('ifcfg-eth0')).to eq ['eth0', nil, nil]
        expect(described_class.parse_filename('ifcfg-lo')).to eq ['lo', nil, nil]
        expect(described_class.parse_filename('ifcfg-venet0')).to eq ['venet0', nil, nil]
      end
    end

    context 'range file name' do
      it 'returns the device name and range number' do
        expect(described_class.parse_filename('ifcfg-eth0-range0')).to eq ['eth0', 0, nil]
        expect(described_class.parse_filename('ifcfg-eth1-range10')).to eq ['eth1', 10, nil]
      end
    end

    context 'clone file name' do
      it 'returns the device name and clone number' do
        expect(described_class.parse_filename('ifcfg-eth0:0')).to eq ['eth0', nil, 0]
        expect(described_class.parse_filename('ifcfg-eth1:12')).to eq ['eth1', nil, 12]
        expect(described_class.parse_filename('ifcfg-venet0:999')).to eq ['venet0', nil, 999]
      end
    end
  end

  context 'primary file' do
    let(:config_file) { described_class.create(*primary_file) }

    it 'returns a PrimaryFile' do
      expect(config_file).to be_a Iface::PrimaryFile
    end

    context 'static' do
      let(:bootproto) { 'none' }

      context '#ip_address' do
        it 'returns the IP address' do
          expect(config_file.ip_address).to eq ipaddr
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
      let(:bootproto) { 'dhcp' }

      context '#ip_address' do
        it 'returns nil' do
          expect(config_file.ip_address).to be_nil
        end
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

  context 'clone file' do
    let(:config_file) { described_class.create(*clone_file) }

    it 'returns a CloneFile' do
      expect(config_file).to be_a Iface::CloneFile
    end

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

  context 'range file' do
    let(:config_file) { described_class.create(*range_file) }

    it 'returns a RangeFile' do
      expect(config_file).to be_a Iface::RangeFile
    end

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
end

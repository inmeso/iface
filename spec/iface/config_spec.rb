# frozen_string_literal: true

RSpec.describe Iface::Config do
  let(:bootproto) { 'none' }
  let(:ipaddr) { '173.208.232.2' }
  let(:ipaddr_middle) { '173.208.232.12' }
  let(:ipaddr_end) { '173.208.232.30' }
  let(:clone_num) { 123 }
  let(:range_num) { 456 }
  let(:vlan_id) { 789 }
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

  let(:config) do
    described_class.new.tap do |c|
      c.add(*primary_file)
      c.add(*clone_file)
      c.add(*range_file)
      c.add(*vlan_file)
    end
  end

  describe '#[]' do
    context 'device is not defined' do
      it 'returns nil' do
        expect(config['eth999']).to be_nil
      end
    end

    context 'primary for device is defined' do
      it 'returns the PrimaryFile for the device' do
        eth0 = config['eth0']
        expect(eth0).to be_a Iface::PrimaryFile
      end
    end
  end

  describe '#primary' do
    context 'static' do
      context 'when primary IP is not reserved' do
        let(:ipaddr) { '173.208.232.2' }

        it 'returns the PrimaryFile' do
          expect(config.primary).to be_a Iface::PrimaryFile
        end
      end

      context 'when primary IP is reserved' do
        let(:ipaddr) { '192.168.100.50' }

        it 'returns nil' do
          expect(config.primary).to be_nil
        end
      end
    end

    context 'dhcp' do
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

      it 'returns the PrimaryFile' do
        expect(config.primary).to be_a Iface::PrimaryFile
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe Iface::Config do
  let(:content) do
    StringIO.new(<<~__EOF__)
      DEVICE=eth0
      BOOTPROTO=none
      HWADDR=00:30:48:d7:04:48
      NM_CONTROLLED=yes
      ONBOOT=yes
      TYPE=Ethernet
      UUID="08562816-c7ce-4364-8cbd-2505faee246e"
      IPADDR=173.208.232.90
      NETMASK=255.255.255.248
      GATEWAY=173.208.232.89
      USERCTL=no
      PEERDNS=yes
      IPV6INIT=no
    __EOF__
  end
  let(:config) { described_class.new.add(content) }

  context '#primary_ip' do
    # expect(config)
  end
end

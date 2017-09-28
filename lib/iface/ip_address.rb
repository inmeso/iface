# frozen_string_literal: true

require 'ipaddr'

module Iface
  # Represents an IP address including prefix length
  class IpAddress
    def self.create(str)
      ipaddr = IPAddr.new(str)
      (ipaddr.ipv4? ? IpV4Address : IpV6Address).new(ipaddr)
    end

    def initialize(ip_address)
      @ipaddr = ip_address.is_a?(IPAddr) ? ip_address : IPAddr.new(ip_address)
      @mask_addr = @ipaddr.instance_eval { @mask_addr }
      @_bitmask = @mask_addr.to_s(2)
      @inverse_mask_addr = @_bitmask.tr('01', '10').to_i(2)
    end

    def cidr_mask
      case diff = full_mask - @mask_addr
      when 0
        full_cidr_mask
      when 1
        full_cidr_mask - 1
      else
        full_cidr_mask - Math.log2(diff).ceil
      end
    end

    def to_i
      @ipaddr.to_i
    end

    def to_s
      @ipaddr.to_s
    end

    def full_mask
      raise NotImplementedError
    end

    def full_cidr_mask
      raise NotImplementedError
    end

    def ==(other)
      self.class == other.class && __state__ == other.__state__
    end

    protected

    def __state__
      @ipaddr
    end
  end

  # Represents an IPv4 address
  class IpV4Address < IpAddress
    def self.from_numeric(numeric)
      new(IPAddr.new_ntoh([numeric].pack('N')))
    end

    def initialize(ip_address)
      super
      raise ArgumentError, "Expected IPv4, got IPv6: #{ip_address}" unless @ipaddr.ipv4?
    end

    def full_mask
      IPAddr::IN4MASK
    end

    def full_cidr_mask
      32
    end
  end

  # Represents an IPv6 address
  class IpV6Address < IpAddress
    MASK_32 = 0xffffffffffffffff

    def self.from_numeric(numeric)
      new(IPAddr.new_ntoh([(numeric >> 96), (numeric >> 64) & MASK_32, (numeric >> 32) & MASK_32, numeric & MASK_32].pack('N*')))
    end

    def initialize(ip_address)
      super
      raise ArgumentError, "Expected IPv6, got IPv4: #{ip_address}" unless @ipaddr.ipv6?
    end

    def full_mask
      IPAddr::IN6MASK
    end

    def full_cidr_mask
      128
    end
  end
end

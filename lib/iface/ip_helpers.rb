# frozen_string_literal: true

# Adds IP-related methods to all Integers
class Integer
  Mask32_ = 0xffffffffffffffff # rubocop:disable Style/ConstantName

  def to_ip(ipver = 4)
    to_ipaddr(ipver).to_s
  end

  def to_ipaddr4
    IPAddr.new_ntoh([self].pack('N'))
  end

  def to_ipaddr6
    IPAddr.new_ntoh([(self >> 96), (self >> 64) & Mask32_, (self >> 32) & Mask32_, self & Mask32_].pack('N*'))
  end

  def to_ipaddr(ipver = 4)
    case ipver
    when 4
      to_ipaddr4
    when 6
      to_ipaddr6
    else
      raise ArgumentError, "Expecting argument 1 to be either 4 or 6; got #{ipver.inspect}"
    end
  end

  def max_mask_bits
    to_s(2)[/(0*)$/, 1].size
  end
end

# frozen_string_literal: true

require 'ipaddr'

module Iface
  # Represents an IP address including subnet mask
  class IpAddress
    def initialize(*args)
      @ipaddr = IPAddr.new(*args)
      @_bitmask = @ipaddr.instance_eval { @mask_addr.to_s(2) }
      @inverse_mask_addr = @_bitmask.tr('01', '10').to_i(2)
    end
  end
end

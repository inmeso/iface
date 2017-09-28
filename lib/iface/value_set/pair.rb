# frozen_string_literal: true

module Iface
  class ValueSet
    # Represents a NAME=value pair
    #
    # This serves as the default class for a NAME key. Use `::create` to
    # instantiate a specialization of this class, if available.
    class Pair
      attr_reader :name
      attr_accessor :value

      def self.create(name_or_line, value = nil, value_set:)
        # get name and value
        if value
          name = name_or_line.to_s.upcase
        else
          match = name_or_line.match(/(^[A-Z0-9_]+?)="?(.*?)"?$/)
          raise ArgumentError, "Expected pattern NAME=value; got #{name_or_line.inspect}" unless match
          name = match[1]
          value = match[2]&.sub(/^"/, '')&.sub(/"$/, '')
        end

        # find matching class and instantiate
        VAR_HANDLERS.fetch(name, self).new(name, value, value_set)
      end

      def initialize(name, value, value_set) # :nodoc:
        @name = name.to_s.upcase
        @value = value
        @value_set = value_set
      end

      def raw_value
        @value
      end

      def to_s
        "#{name}=\"#{value}\""
      end
    end

    # Represents a pair for IPADDR
    class IpV4Primary < Pair
      def initialize(_name, value, value_set)
        super('IPADDR', value, value_set)
        self.value = value
      end

      def value
        IpV4Address.from_numeric(@value).to_s
      end

      def value=(new_value)
        @value = IpV4Address.new(new_value).to_i
        self
      end
    end

    # Represents a pair for IPV6ADDR, which is output in the form
    # IPV6ADDR="ipv6-address/prefix-length"
    class IpV6Primary < Pair
      def initialize(_name, value, value_set)
        super('IPV6ADDR', value, value_set)
        self.value = value
      end

      def value
        "#{IpV6Address.from_numeric(@value)}/#{@mask}"
      end

      def value=(new_value)
        ip, mask = new_value.split(%r{/})
        ipaddr = IpV6Address.new(ip)
        @value = ipaddr.to_i
        @mask = mask || 64
        @value_set['ipv6_secondaries']&.filter_primary!(@value)
        self
      end
    end

    # Represents a pair for IPV6ADDR_SECONDARIES
    class IpV6Secondaries < Pair
      def initialize(_name, value, value_set)
        super('IPV6ADDR_SECONDARIES', value, value_set)
        case value
        when String
          self.value = value.split(/ +/)
        when Array
          self.value = value
        else
          raise ArgumentError, "Expected String or Array; got #{value.class.name}: #{value.inspect}"
        end
      end

      def value=(new_value)
        ips = new_value.map do |ip_with_mask|
          ip, mask = ip_with_mask.split(%r{/})
          [IpV6Address.new(ip).to_i, mask || 128]
        end.uniq.sort
        @value = ips
        ipv6_primary = @value_set.fetch_raw('ipv6addr')
        filter_primary!(ipv6_primary) if ipv6_primary
        self
      end

      def value
        @value.map { |ip_num, mask| "#{IpV6Address.from_numeric(ip_num)}/#{mask}" }.join(' ')
      end

      def filter_primary!(primary_num)
        @value = @value.reject { |ip_num, _mask| ip_num == primary_num }
        self
      end
    end

    VAR_HANDLERS = { # rubocop:disable Style/MutableConstant
      'IPADDR' => IpV4Primary,
      'IPV6ADDR' => IpV6Primary,
      'IPV6ADDR_SECONDARIES' => IpV6Secondaries
    }
  end
end

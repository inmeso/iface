# frozen_string_literal: true

require_relative 'value_set/pair'

module Iface
  # Represents a generic set of NAME=value pairs
  class ValueSet
    def initialize(io)
      @vars = {}
      io.each_line do |line|
        edited_line = line.sub(/#.*$/, '').strip
        next if edited_line.empty?
        pair = Pair.create(edited_line, value_set: self)
        @vars[pair.name] = pair
      end
    end

    def [](name)
      @vars[name.upcase]&.value
    end

    def []=(name, value)
      key = name.upcase
      if @vars.key?(key)
        @vars[key].value = value
      else
        @vars[key] = Pair.create(key, value, value_set: self)
      end
    end

    def fetch_raw(name)
      @vars[name.upcase]&.raw_value
    end

    def key?(name)
      @vars.key?(name.upcase)
    end
    alias has_key? key?

    def to_s
      "#{@vars.values.map(&:to_s).join("\n")}\n"
    end
  end

  # Represents a set of NAME=value pairs that would appear in a primary
  # interface file, e.g. one named "ifcfg-eth0"
  class PrimaryInterface < ValueSet
    def make_static
      self['BOOTPROTO'] = 'none'
    end

    def disable_nm
      self['NM_CONTROLLED'] = 'no'
    end

    def use_ipv6
      self['IPV6INIT'] = 'yes'
    end
  end
end

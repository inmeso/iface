# frozen_string_literal: true

require_relative 'ip_helpers'
require_relative 'value_set'

# Monkey-patches `String` to add helper methods
class String
  def decamelize
    gsub(/[A-Z]/) { |m| $` == '' ? m.downcase : "_#{m.downcase}" }
  end
end

module Iface
  # Base class for a network interface config file
  #
  # When reading from an existing file, use `.create`. When creating a config
  # programatically for writing to a file, instantiate one of the subclasses
  # (e.g. `PrimaryFile.new`).
  class ConfigFile
    attr_reader :filename, :device, :vars

    def self.create(filename, io)
      fname = File.split(filename).last
      device, range_num, clone_num = parse_filename(fname)

      FILE_TYPES.each do |klass|
        if klass.recognize?(device, range_num, clone_num)
          return klass.new(filename, device, range_num, clone_num, io)
        end
      end

      raise ArgumentError, "Input not recognized from file #{fname}: #{[device, range_num, clone_num, vars].inspect}"
    end

    def self.parse_filename(filename)
      match = filename.match(/\Aifcfg-(\w+)((-range(\d+))|(:(\d+)))?\Z/)
      return unless match
      device, _skip0, _skip1, range_num, _skip2, clone_num = match.captures
      [device, range_num&.to_i, clone_num&.to_i]
    end

    def self.recognize?(_device, _range_num, _clone_num)
      false
    end

    def self.file_type_name
      name.split('::').last[0..-5].decamelize.to_sym if name.match?(/File\Z/)
    end

    def initialize(filename, device, _range_num, _clone_num, io)
      @filename = filename
      @device = device
      @vars = value_set_class.new(io)
    end

    def static?
      raise NotImplementedError
    end

    def include?(_ip)
      raise NotImplementedError
    end

    def value_set_class
      ValueSet
    end

    def to_s
      @vars.to_s
    end
  end

  # Represents a primary config file (not loopback, range or clone file)
  #
  # These are files named like "ifcfg-eth0".
  class PrimaryFile < ConfigFile
    def self.recognize?(device, range_num, clone_num)
      device != 'lo' && range_num.nil? && clone_num.nil?
    end

    def ip_address
      @vars['ipaddr']
    end

    def ip_address=(new_ip)
      @vars['ipaddr'] = new_ip
      make_static
      disable_nm
    end

    def ipv6_address
      @vars['ipv6addr']
    end

    def ipv6_address=(new_ip)
      @vars['ipv6addr'] = new_ip
      make_static
      disable_nm
    end

    def ipv6_secondaries
      @vars['ipv6addr_secondaries']&.split(/\s+/)
    end

    def ipv6_secondaries=(new_ips)
      @vars['ipv6addr_secondaries'] = new_ips
      make_static
      disable_nm
    end

    def value_set_class
      PrimaryInterface
    end

    def make_static
      @vars.make_static unless static?
    end

    def disable_nm
      @vars.disable_nm
    end

    def nm_controlled?
      @vars['nm_controlled'] == 'yes'
    end

    def use_ipv6
      @vars.use_ipv6
    end

    def static?
      @vars['bootproto'] == 'none'
    end

    def include?(ip)
      ip_address == ip
    end
  end

  # Represents a clone config file (single IP address)
  #
  # These are files named like "ifcfg-eth0:1".
  class CloneFile < ConfigFile
    attr_reader :ip_address, :clone_num

    def self.recognize?(_device, _range_num, clone_num)
      !clone_num.nil?
    end

    def initialize(filename, device, _range_num, clone_num, io)
      super
      @ip_address = vars['ipaddr']
      @clone_num = clone_num
    end

    def static?
      true
    end

    def include?(ip)
      @ip_address == ip
    end
  end

  # Represents a range config file (a range of IP addresses)
  #
  # These are files named like "ifcfg-eth0-range0".
  class RangeFile < ConfigFile
    attr_reader :start_clone_num

    def self.recognize?(_device, range_num, _clone_num)
      !range_num.nil?
    end

    def initialize(filename, device, range_num, clone_num, io)
      super
      @start_ip_num = string_to_ip_num(vars['ipaddr_start'])
      @end_ip_num = string_to_ip_num(vars['ipaddr_end'])
      @start_clone_num = vars['clonenum_start']&.to_i
    end

    def static?
      true
    end

    def include?(ip)
      ip_num = string_to_ip_num(ip)
      @start_ip_num <= ip_num && ip_num <= @end_ip_num
    end

    def start_ip_num
      @start_ip_num.to_ip
    end

    def end_ip_num
      @end_ip_num.to_ip
    end

    def string_to_ip_num(str)
      str.split('.').collect { |x| x.to_i.to_s(16).rjust(2, '0') }.join.hex
    end
  end

  # Represents a loopback file (device "lo")
  class LoopbackFile < ConfigFile
    def self.recognize?(device, _range_num, _clone_num)
      device == 'lo'
    end

    def initialize(filename, device, range_num, _clone_num, io)
      super
      @ip_address = vars['ipaddr']
    end

    def static?
      true
    end

    def include?(ip)
      @ip_address == ip
    end
  end

  FILE_TYPES = [
    PrimaryFile,
    CloneFile,
    RangeFile,
    LoopbackFile
  ].freeze
end

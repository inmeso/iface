# frozen_string_literal: true

require_relative 'ip_helpers'
require_relative 'value_set'

class String
  def decamelize
    gsub(/[A-Z]/) {|m| $` == '' ? m.downcase : "_#{m.downcase}"}
  end
end

module Iface
  # Base class for a network interface config file
  class ConfigFile
    def self.create(filename, io)
      fname = File.split(filename).last
      device, range_num, clone_num = parse_filename(fname)
      vars = ValueSet.new(io)

      FILE_TYPES.each do |klass|
        if klass.recognize?(device, range_num, clone_num, vars)
          return klass.new(filename, device, range_num, clone_num, vars)
        end
      end

      raise ArgumentError, "Input not recognized from file #{fname}: #{[device, range_num, clone_num, vars].inspect}"
    end

    def self.parse_filename(filename)
      match = filename.match(/\Aifcfg-(\w+)((-range(\d+))|(:(\d+)))?\Z/)
      if match
        device, _skip0, _skip1, range_num, _skip2, clone_num = match.captures
        [device, range_num&.to_i, clone_num&.to_i]
      end
    end

    def self.recognize?(_device, _range_num, _clone_num, _vars)
      false
    end

    def self.file_type_name
      if self.name =~ /File\Z/
        self.name.split('::').last[0..-5].decamelize.to_sym
      else
        nil
      end
    end

    def initialize(filename, device, _range_num, _clone_num, _vars)
      @filename = filename
      @device = device
    end

    def static?
      raise NotImplementedError
    end

    def include?(_ip)
      raise NotImplementedError
    end
  end

  # Represents a primary config file (not loopback, range or clone file)
  #
  # These are files named like "ifcfg-eth0".
  class PrimaryFile < ConfigFile
    attr_reader :ip_address, :ipv6_address, :ipv6_secondaries

    def self.recognize?(device, range_num, clone_num, _vars)
      device != 'lo' && range_num.nil? && clone_num.nil?
    end

    def initialize(filename, device, range_num, clone_num, vars)
      super
      if (vars['bootproto'] == 'static') || (vars['bootproto'] == 'none') # RHEL6 uses "none"
        @ip_address = vars['ipaddr']
        @ipv6_address = vars['ipv6addr']
        @ipv6_secondaries = vars['ipv6addr_secondaries']&.split(/\s+/)
      end
    end

    def static?
      !@ip_address.nil?
    end

    def include?(ip)
      @ip_address == ip
    end
  end

  # Represents a clone config file (single IP address)
  #
  # These are files named like "ifcfg-eth0:1".
  class CloneFile < ConfigFile
    attr_reader :ip_address, :clone_num

    def self.recognize?(_device, _range_num, clone_num, _vars)
      !clone_num.nil?
    end

    def initialize(filename, device, _range_num, clone_num, vars)
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

    def self.recognize?(_device, range_num, _clone_num, _vars)
      !range_num.nil?
    end

    def initialize(filename, device, range_num, clone_num, vars)
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

  class LoopbackFile < ConfigFile
    def self.recognize?(device, _range_num, _clone_num, _vars)
      device == 'lo'
    end
  end

  FILE_TYPES = [
    PrimaryFile,
    CloneFile,
    RangeFile,
    LoopbackFile
  ].freeze
end

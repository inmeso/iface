# frozen_string_literal: true

require_relative 'config_file'
require 'ipaddr'

module Iface
  # Represents a set of ConfigFiles for network interface configuration
  class Config
    Reserved_IP_Ranges = %w[10.0.0.0/8 192.168.0.0/16].collect { |i| IPAddr.new(i) }

    def self.discover(pattern)
      new.tap do |config|
        Dir.glob(pattern) do |fullname|
          File.open(fullname) { |io| config.add(fullname, io) }
        end
      end
    end

    def initialize
      @files = {}
    end

    def add(filename, io)
      file = ConfigFile.create(filename, io)
      file_type = file.class.file_type_name
      if @files.key?(file_type)
        @files[file_type] << file
      else
        @files[file_type] = [file]
      end
      self
    end

    # Returns the PrimaryFile
    #
    # There should be 0 or 1 of these; else it's an error.
    def primary
      result = @files[:primary].select do |file|
        if !file.static?
          true
        elsif file.ip_address.nil?
          false
        else
          ipaddr = IPAddr.new(file.ip_address)
          Reserved_IP_Ranges.none? { |range| range.include?(ipaddr) }
        end
      end

      case result.size
      when 0
        nil
      when 1
        result.first
      else
        raise "Expected 0 or 1 primary files; found #{result.size}"
      end
    end
  end
end

# frozen_string_literal: true

module Iface
  # Represents a set of NAME=value pairs
  class ValueSet
    # Represents a NAME=value pair
    class Pair
      attr_reader :name, :value

      def initialize(line)
        match = line.match(/(^[A-Z0-9_]+)="?(.*?)"?$/)
        raise ArgumentError, "Expected pattern NAME=value; got #{line.inspect}" unless match
        @name = match[1]
        @value = match[2]&.sub(/^"/, '')&.sub(/"$/, '')
      end

      def to_s
        "#{@name}=\"#{@value}\""
      end
    end

    def initialize(io)
      @vars = {}
      io.each_line do |line|
        edited_line = line.sub(/#.*$/, '').strip
        next if edited_line.empty?
        pair = Pair.new(edited_line)
        @vars[pair.name] = pair
      end
    end

    def [](name)
      @vars[name.upcase]&.value
    end

    def key?(name)
      @vars.key?(name.upcase)
    end
    alias has_key? key?

    def to_s
      @vars.values.map(&:to_s).join("\n")
    end
  end
end

# frozen_string_literal: true

module Iface
  # Represents a set of NAME=value pairs
  class ValueSet
    # Represents a NAME=value pair
    class Pair
      attr_reader :name, :value

      def initialize(line)
        match = line.sub(/#.*$/, '').strip.match(/(^[A-Z0-9_]+)="?(.*?)"?$/)
        raise ArgumentError, 'Pattern NAME=value expected' unless match
        @name = match[1]
        @value = match[2]&.sub(/^"/, '')&.sub(/"$/, '')
      end

      def to_s
        "#{@name}=\"#{@value}\""
      end
    end

    def initialize(io)
      @vars = io.inject({}) do |memo, line|
        pair = Pair.new(line)
        memo.merge(pair.name => pair)
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

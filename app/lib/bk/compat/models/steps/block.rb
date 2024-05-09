# frozen_string_literal: true

module BK
  module Compat
    class BlockStep
      attr_accessor :conditional, :depends_on, :key, :prompt

      def initialize(key:, conditional: nil, depends_on: [], prompt: nil)
        @key = key
        @depends_on = depends_on
        @conditional = conditional
        @prompt = prompt
      end

      def <<(_obj)
        raise 'Can not add to a block step'
      end

      def to_h
        { block: @key, key: @key }.tap do |h|
          # rename conditional to if (a reserved word as an attribute or instance variable is complicated)
          h[:depends_on] = @depends_on unless @depends_on.empty?
          h[:if] = @conditional unless @conditional.nil?
          h[:prompt] = @prompt unless @prompt.nil?
        end
      end

      def instantiate
        dup
      end
    end
  end
end 
